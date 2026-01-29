//
//  ChapterView.swift
//  WrittenWord
//
//  Enhanced chapter display with interlinear word lookup and annotation support
//

import SwiftUI
import SwiftData
import PencilKit

struct ChapterView: View {
    let chapter: Chapter
    let onChapterChange: (Chapter) -> Void
    var onVerseInteraction: (() -> Void)? = nil

    @AppStorage("fontSize") private var fontSize: Double = 16.0
    @AppStorage("lineSpacing") private var lineSpacing: Double = 6.0
    @AppStorage("fontFamily") private var fontFamily: FontFamily = .system
    @AppStorage("colorTheme") private var colorTheme: ColorTheme = .system

    @Environment(\.modelContext) private var modelContext
    @Query private var allNotes: [Note]

    // State for interlinear word lookup
    @State private var selectedWord: Word?
    @State private var showInterlinearLookup = false
    @State private var selectedVerse: Verse?

    // State for highlighting (fallback when no interlinear data)
    @State private var showHighlightMenu = false
    @State private var selectedText = ""
    @State private var selectedRange: NSRange?
    @State private var selectedHighlightColor: HighlightColor = .yellow
    @State private var selectionDebounceTask: Task<Void, Never>?

    // Annotation state
    @State private var selectedTool: AnnotationTool = .none
    @State private var selectedColor: Color = .black
    @State private var penWidth: CGFloat = 2.0
    @State private var showingColorPicker = false
    @State private var canvasView = PKCanvasView()
    @State private var drawing = PKDrawing()

    private var sortedVerses: [Verse] {
        chapter.verses.sorted { $0.number < $1.number }
    }

    private var chapterNote: Note? {
        allNotes.first { $0.chapter?.id == chapter.id }
    }

    var body: some View {
        ZStack {
            // Main content
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(sortedVerses) { verse in
                        VerseRow(
                            verse: verse,
                            fontSize: fontSize,
                            lineSpacing: lineSpacing,
                            fontFamily: fontFamily,
                            colorTheme: colorTheme,
                            isAnnotationMode: selectedTool != .none,
                            onTextSelected: { range, text in
                                handleTextSelection(verse: verse, range: range, text: text)
                            },
                            onBookmark: {
                                bookmarkVerse(verse)
                            }
                        )
                        .padding(.vertical, 4)
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.vertical)
            }

            // Annotation canvas overlay
            AnnotationCanvasView(
                drawing: $drawing,
                selectedTool: selectedTool,
                selectedColor: selectedColor,
                penWidth: penWidth,
                canvasView: $canvasView
            )
            .allowsHitTesting(selectedTool != .none)
        }
        .navigationTitle("\(chapter.book?.name ?? "") \(chapter.number)")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                annotationToolbarButton
            }
        }
        .sheet(isPresented: $showInterlinearLookup) {
            if let word = selectedWord {
                InterlinearLookupView(word: word)
            }
        }
        .sheet(isPresented: $showHighlightMenu) {
            highlightMenuView
        }
        .sheet(isPresented: $showingColorPicker) {
            ColorPicker("Select Color", selection: $selectedColor)
                .padding()
                .presentationDetents([.medium])
        }
        .safeAreaInset(edge: .bottom) {
            if selectedTool != .none {
                AnnotationToolbar(
                    selectedTool: $selectedTool,
                    selectedColor: $selectedColor,
                    penWidth: $penWidth,
                    showingColorPicker: $showingColorPicker
                )
                .transition(.move(edge: .bottom))
            }
        }
        .onAppear {
            loadDrawing()
        }
        .onDisappear {
            saveDrawing()
        }
    }

    private var annotationToolbarButton: some View {
        Button {
            withAnimation {
                if selectedTool == .none {
                    selectedTool = .pen
                } else {
                    selectedTool = .none
                    saveDrawing()
                }
            }
        } label: {
            Image(systemName: selectedTool == .none ? "pencil.tip.crop.circle" : "pencil.tip.crop.circle.fill")
                .foregroundColor(selectedTool == .none ? .primary : .blue)
        }
    }

    private var highlightMenuView: some View {
        VStack(spacing: 20) {
            Text("Highlight Text")
                .font(.headline)

            Text(selectedText)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

            // Color palette
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                ForEach(HighlightColor.allCases, id: \.self) { color in
                    Button {
                        createHighlight(color: color)
                    } label: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color.color)
                            .frame(height: 50)
                            .overlay(
                                Text(color.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.black.opacity(0.7))
                            )
                    }
                }
            }
            .padding()

            Button("Cancel") {
                showHighlightMenu = false
            }
            .padding()
        }
        .padding()
        .presentationDetents([.medium])
    }

    private func handleTextSelection(verse: Verse, range: NSRange, text: String) {
        // Notify parent that user interacted with verses (for sidebar collapse)
        onVerseInteraction?()

        selectedVerse = verse
        selectedRange = range
        selectedText = text

        // Cancel any pending debounce task
        selectionDebounceTask?.cancel()

        // Debounce the menu display to allow multi-word selection
        selectionDebounceTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 500_000_000) // 500ms delay

                if !Task.isCancelled {
                    // Check if we have interlinear data for this word
                    if let word = WordLookupService.findWord(in: verse, for: range) {
                        // Show interlinear lookup
                        selectedWord = word
                        showInterlinearLookup = true
                    } else {
                        // Fallback to highlighting menu
                        showHighlightMenu = true
                    }
                }
            } catch {
                // Task was cancelled, do nothing
            }
        }
    }

    private func createHighlight(color: HighlightColor) {
        guard let verse = selectedVerse,
              let range = selectedRange else {
            return
        }

        let highlight = Highlight(
            verseId: verse.id,
            startIndex: range.location,
            endIndex: range.location + range.length,
            color: color.color,
            text: selectedText,
            verse: verse
        )

        modelContext.insert(highlight)
        try? modelContext.save()

        showHighlightMenu = false
        selectedRange = nil
        selectedText = ""
        selectedVerse = nil
    }

    private func bookmarkVerse(_ verse: Verse) {
        let bookmark = Bookmark(
            title: "",
            verse: verse,
            category: BookmarkCategory.general.rawValue,
            color: BookmarkCategory.general.color
        )
        modelContext.insert(bookmark)
        try? modelContext.save()
    }

    private func loadDrawing() {
        if let note = chapterNote, let drawingData = note.drawing {
            do {
                drawing = try PKDrawing(data: drawingData.dataRepresentation())
                canvasView.drawing = drawing
            } catch {
                print("Failed to load drawing: \(error)")
            }
        }
    }

    private func saveDrawing() {
        // Only save if there's actual content
        guard !drawing.bounds.isEmpty else { return }

        if let note = chapterNote {
            // Update existing note
            note.drawing = drawing
        } else {
            // Create new note for chapter
            let note = Note(chapter: chapter, drawing: drawing)
            modelContext.insert(note)
        }

        try? modelContext.save()
    }
}
