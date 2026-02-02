//
//  ChapterView.swift - FIXED
//  WrittenWord
//
//  Fixed state capture issue in UnifiedSelectionMenu presentation
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
    @Query private var allHighlights: [Highlight]

    // State for unified selection menu (interlinear + highlighting)
    @State private var selectedWord: Word?
    @State private var selectedVerse: Verse?
    @State private var showUnifiedSelectionMenu = false
    @State private var selectedText = ""
    @State private var selectedRange: NSRange?
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
        allNotes.first { $0.chapter?.id == chapter.id && $0.verse == nil }
    }

    var body: some View {
        ZStack {
            colorTheme.backgroundColor.ignoresSafeArea()

            ScrollView {
                WordSelectableChapterTextView(
                    verses: sortedVerses,
                    highlights: allHighlights,
                    fontSize: fontSize,
                    fontFamily: fontFamily,
                    lineSpacing: lineSpacing,
                    colorTheme: colorTheme,
                    onTextSelected: handleTextSelection
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .navigationTitle("\(chapter.book?.name ?? "") \(chapter.number)")
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if let previous = previousChapter {
                    Button {
                        onChapterChange(previous)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }

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

                if let next = nextChapter {
                    Button {
                        onChapterChange(next)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
            }
        }
        .sheet(isPresented: $showUnifiedSelectionMenu, onDismiss: {
            // Clear selection when sheet is dismissed
            clearSelection()
        }) {
            // Capture state at the moment of presentation
            unifiedSelectionMenuView
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

    // MARK: - Computed Properties

    private var previousChapter: Chapter? {
        guard let book = chapter.book else { return nil }
        let chapters = book.chapters.sorted { $0.number < $1.number }
        guard let currentIndex = chapters.firstIndex(of: chapter), currentIndex > 0 else {
            return nil
        }
        return chapters[currentIndex - 1]
    }

    private var nextChapter: Chapter? {
        guard let book = chapter.book else { return nil }
        let chapters = book.chapters.sorted { $0.number < $1.number }
        guard let currentIndex = chapters.firstIndex(of: chapter),
              currentIndex < chapters.count - 1 else {
            return nil
        }
        return chapters[currentIndex + 1]
    }

    // MARK: - Unified Selection Menu View

    @ViewBuilder
    private var unifiedSelectionMenuView: some View {
        if let verse = selectedVerse,
           let range = selectedRange,
           !selectedText.isEmpty {
            let verseHighlights = allHighlights.filter { $0.verseId == verse.id }
            
            UnifiedSelectionMenu(
                selectedText: selectedText,
                selectedWord: selectedWord,
                verse: verse,
                range: range,
                existingHighlights: verseHighlights,
                onHighlight: { color in
                    createOrToggleHighlight(color: color)
                },
                onRemoveHighlight: { color in
                    removeHighlight(color: color)
                },
                onCancel: {
                    showUnifiedSelectionMenu = false
                }
            )
            .presentationDetents([.medium, .large])
        } else {
            // Fallback view - shouldn't normally show
            VStack(spacing: 16) {
                Text("Selection Error")
                    .font(.headline)
                Text("Please try selecting text again.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Button("Close") {
                    showUnifiedSelectionMenu = false
                    clearSelection()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .padding()
            .presentationDetents([.medium])
        }
    }

    // MARK: - Text Selection Handler

    private func handleTextSelection(verse: Verse, range: NSRange, text: String) {
        // Guard against empty text
        guard !text.isEmpty else {
            return
        }
        
        onVerseInteraction?()

        // Cancel any pending debounce
        selectionDebounceTask?.cancel()

        // Immediately update state
        selectedVerse = verse
        selectedRange = range
        selectedText = text

        // Debounce the menu presentation to allow multi-word selection
        selectionDebounceTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 300_000_000) // 300ms

                if !Task.isCancelled {
                    // Look up word data
                    selectedWord = WordLookupService.findWord(in: verse, for: range)
                    
                    // Show menu
                    showUnifiedSelectionMenu = true
                }
            } catch {
                // Task cancelled - user is still selecting
            }
        }
    }

    private func clearSelection() {
        selectedVerse = nil
        selectedRange = nil
        selectedText = ""
        selectedWord = nil
        selectionDebounceTask?.cancel()
    }

    // MARK: - Highlight Management

    private func createOrToggleHighlight(color: HighlightColor) {
        guard let verse = selectedVerse, let range = selectedRange else { return }

        let existingHighlight = allHighlights.first { highlight in
            highlight.verseId == verse.id &&
            highlight.startIndex == range.location &&
            highlight.endIndex == range.location + range.length &&
            colorsMatch(highlight.highlightColor, color.color)
        }

        if let existingHighlight = existingHighlight {
            modelContext.delete(existingHighlight)
        } else {
            let highlight = Highlight(
                verseId: verse.id,
                startIndex: range.location,
                endIndex: range.location + range.length,
                color: color.color,
                text: selectedText,
                verse: verse
            )
            modelContext.insert(highlight)
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save highlight: \(error)")
        }
        
        showUnifiedSelectionMenu = false
    }

    private func removeHighlight(color: HighlightColor) {
        guard let verse = selectedVerse, let range = selectedRange else { return }

        let highlightToRemove = allHighlights.first { highlight in
            highlight.verseId == verse.id &&
            highlight.startIndex == range.location &&
            highlight.endIndex == range.location + range.length &&
            colorsMatch(highlight.highlightColor, color.color)
        }

        if let highlightToRemove = highlightToRemove {
            modelContext.delete(highlightToRemove)
            do {
                try modelContext.save()
            } catch {
                print("Failed to remove highlight: \(error)")
            }
        }
    }

    private func colorsMatch(_ c1: Color, _ c2: Color) -> Bool {
        let uiColor1 = UIColor(c1)
        let uiColor2 = UIColor(c2)
        return uiColor1.cgColor.components?.dropLast() == uiColor2.cgColor.components?.dropLast()
    }

    // MARK: - Drawing Management

    private func loadDrawing() {
        if let note = chapterNote {
            canvasView.drawing = note.drawing
            drawing = note.drawing
        }
    }

    private func saveDrawing() {
        let currentDrawing = canvasView.drawing

        if let note = chapterNote {
            note.drawing = currentDrawing
            note.updatedAt = Date()
        } else if !currentDrawing.strokes.isEmpty {
            let newNote = Note(
                title: "Chapter \(chapter.number) Annotations",
                content: "",
                drawing: currentDrawing,
                verseReference: "\(chapter.book?.name ?? "") \(chapter.number)",
                isMarginNote: false,
                chapter: chapter,
                verse: nil
            )
            modelContext.insert(newNote)
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save drawing: \(error)")
        }
    }
}
