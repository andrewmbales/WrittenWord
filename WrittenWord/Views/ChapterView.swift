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
    @AppStorage("notePosition") private var notePosition: NotePosition = .right

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

    // Multi-verse selection state
    @State private var isMultiSelectMode = false
    @State private var selectedVerses: Set<UUID> = []
    @State private var showMultiHighlightPalette = false

    // Annotation state
    @State private var selectedTool: AnnotationTool = .none
    @State private var selectedColor: Color = .black
    @State private var penWidth: CGFloat = 2.0
    @State private var showingColorPicker = false
    @State private var canvasView = PKCanvasView()
    @State private var drawing = PKDrawing()

    // Long note state
    @State private var showingNoteEditor = false
    @State private var noteTitle = ""
    @State private var noteContent = ""

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
                        .padding(.leading, notePosition == .left ? 240 : 20)
                        .padding(.trailing, notePosition == .right ? 240 : 20)
                        .background(
                            selectedVerses.contains(verse.id) ?
                            Color.accentColor.opacity(0.15) : Color.clear
                        )
                        .cornerRadius(8)
                        .onTapGesture {
                            if isMultiSelectMode {
                                toggleVerseSelection(verse)
                            }
                        }
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
            ToolbarItem(placement: .navigationBarLeading) {
                if isMultiSelectMode {
                    Button("Cancel") {
                        isMultiSelectMode = false
                        selectedVerses.removeAll()
                    }
                }
            }

            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    // Note button
                    Button {
                        showingNoteEditor = true
                    } label: {
                        Image(systemName: "note.text")
                    }

                    if !isMultiSelectMode {
                        Button {
                            isMultiSelectMode = true
                        } label: {
                            Image(systemName: "checkmark.circle")
                        }
                    } else if !selectedVerses.isEmpty {
                        Button {
                            showMultiHighlightPalette = true
                        } label: {
                            Image(systemName: "highlighter")
                        }
                    }

                    annotationToolbarButton
                }
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
        .sheet(isPresented: $showMultiHighlightPalette) {
            multiHighlightPaletteView
        }
        .sheet(isPresented: $showingColorPicker) {
            ColorPicker("Select Color", selection: $selectedColor)
                .padding()
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $showingNoteEditor) {
            noteEditorView
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
        if let note = chapterNote, !note.drawing.strokes.isEmpty {
            drawing = note.drawing
            canvasView.drawing = drawing
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
            let note = Note(
                title: "",
                content: "",
                drawing: drawing,
                verseReference: "",
                isMarginNote: false,
                chapter: chapter,
                verse: nil
            )
            modelContext.insert(note)
        }

        try? modelContext.save()
    }

    private func toggleVerseSelection(_ verse: Verse) {
        if selectedVerses.contains(verse.id) {
            selectedVerses.remove(verse.id)
        } else {
            selectedVerses.insert(verse.id)
        }
    }

    private var multiHighlightPaletteView: some View {
        VStack(spacing: 20) {
            Text("Highlight \(selectedVerses.count) Verse\(selectedVerses.count == 1 ? "" : "s")")
                .font(.headline)

            // Color palette
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                ForEach(HighlightColor.allCases, id: \.self) { color in
                    Button {
                        createMultiHighlight(color: color)
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
                showMultiHighlightPalette = false
            }
            .padding()
        }
        .padding()
        .presentationDetents([.medium])
    }

    private func createMultiHighlight(color: HighlightColor) {
        // Create a highlight for the entire text of each selected verse
        for verseId in selectedVerses {
            if let verse = sortedVerses.first(where: { $0.id == verseId }) {
                let highlight = Highlight(
                    verseId: verse.id,
                    startIndex: 0,
                    endIndex: verse.text.count,
                    color: color.color,
                    text: verse.text,
                    verse: verse
                )
                modelContext.insert(highlight)
            }
        }

        try? modelContext.save()

        // Clean up
        showMultiHighlightPalette = false
        isMultiSelectMode = false
        selectedVerses.removeAll()
    }

    private var noteEditorView: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Note Title", text: $noteTitle)
                    .font(.headline)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                TextEditor(text: $noteContent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingNoteEditor = false
                        noteTitle = ""
                        noteContent = ""
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .disabled(noteTitle.isEmpty && noteContent.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func saveNote() {
        let note = Note(
            title: noteTitle.isEmpty ? "Untitled Note" : noteTitle,
            content: noteContent,
            drawing: PKDrawing(),
            verseReference: chapter.reference,
            isMarginNote: false,
            chapter: chapter,
            verse: nil
        )
        modelContext.insert(note)
        try? modelContext.save()

        // Clean up
        showingNoteEditor = false
        noteTitle = ""
        noteContent = ""
    }
}
