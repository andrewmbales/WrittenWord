//
//  ChapterView.swift
//  WrittenWord
//
//  FIXED: Proper chapter display with full text rendering
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
    @Query private var allHighlights: [Highlight]

    // State for unified selection menu (interlinear + highlighting)
    @State private var selectedWord: Word?
    @State private var selectedVerse: Verse?
    @State private var showUnifiedSelectionMenu = false
    @State private var selectedText = ""
    @State private var selectedRange: NSRange?
    @State private var selectionDebounceTask: Task<Void, Never>?

    // State for interlinear bottom sheet (lexicon-style word lookup)
    @State private var showInterlinearBottomSheet = false
    @State private var lexiconEntry: LexiconEntry?

    // State for search
    @State private var showSearch = false
    @State private var searchText = ""
    @State private var searchScope: SearchScope = .currentBook

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
    @State private var noteDrawing = PKDrawing()
    @State private var isHandwrittenMode = false
    @State private var noteCanvasView = PKCanvasView()

    private var sortedVerses: [Verse] {
        chapter.verses.sorted { $0.number < $1.number }
    }

    private var chapterNote: Note? {
        allNotes.first { $0.chapter?.id == chapter.id }
    }

    var body: some View {
        ZStack {
            // CRITICAL FIX: Proper content layout
            ScrollView {
                SimpleChapterTextView(
                    verses: sortedVerses,
                    highlights: allHighlights,
                    fontSize: fontSize,
                    fontFamily: fontFamily,
                    lineSpacing: lineSpacing,
                    colorTheme: colorTheme,
                    onTextSelected: { verse, range, text in
                        handleTextSelection(verse: verse, range: range, text: text)
                    }
                )
                .frame(maxWidth: .infinity, alignment: .topLeading)  // ← ADD THIS LINE
            }
            .background(colorTheme.backgroundColor)

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
                    // Search button
                    Button {
                        showSearch = true
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }

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
        .sheet(isPresented: $showUnifiedSelectionMenu) {
            unifiedSelectionMenuView
        }
        .sheet(isPresented: $showInterlinearBottomSheet) {
            interlinearBottomSheetView
        }
        .sheet(isPresented: $showSearch) {
            searchView
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

    private var unifiedSelectionMenuView: some View {
        Group {
            if let verse = selectedVerse, let range = selectedRange {
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
                        clearSelection()
                    }
                )
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var interlinearBottomSheetView: some View {
        Group {
            if let word = selectedWord, let entry = lexiconEntry {
                InterlinearBottomSheet(
                    word: word,
                    lexiconEntry: entry,
                    onCopy: {
                        copyWordToClipboard()
                    },
                    onAddNote: {
                        openNoteEditorForWord()
                    },
                    onHighlight: {
                        openHighlightMenuForWord()
                    },
                    onNavigateToVerse: { verseRef in
                        navigateToVerse(verseRef)
                    }
                )
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var searchView: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                Picker("Search Scope", selection: $searchScope) {
                    Text("Current Book").tag(SearchScope.currentBook)
                    Text("All Books").tag(SearchScope.all)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if !searchText.isEmpty {
                    Text("Search feature coming soon")
                        .foregroundColor(.secondary)
                        .padding()
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showSearch = false
                        searchText = ""
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func handleTextSelection(verse: Verse, range: NSRange, text: String) {
        onVerseInteraction?()

        selectedVerse = verse
        selectedRange = range
        selectedText = text

        selectionDebounceTask?.cancel()

        selectionDebounceTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 500_000_000)

                if !Task.isCancelled {
                    selectedWord = WordLookupService.findWord(in: verse, for: range)

                    if let word = selectedWord {
                        let lexiconService = LexiconService(modelContext: modelContext)
                        lexiconEntry = lexiconService.getLexiconEntry(for: word)
                        showInterlinearBottomSheet = true
                    } else {
                        showUnifiedSelectionMenu = true
                    }
                }
            } catch {
                // Task cancelled
            }
        }
    }

    private func clearSelection() {
        selectedVerse = nil
        selectedRange = nil
        selectedText = ""
        selectedWord = nil
    }

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

        try? modelContext.save()
        showUnifiedSelectionMenu = false
        clearSelection()
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
            try? modelContext.save()
        }

        showUnifiedSelectionMenu = false
        clearSelection()
    }

    private func colorsMatch(_ c1: Color, _ c2: Color) -> Bool {
        let uiColor1 = UIColor(c1)
        let uiColor2 = UIColor(c2)
        return uiColor1.cgColor.components?.dropLast() == uiColor2.cgColor.components?.dropLast()
    }

    private func loadDrawing() {
        if let note = chapterNote, !note.drawing.strokes.isEmpty {
            drawing = note.drawing
            canvasView.drawing = drawing
        }
    }

    private func saveDrawing() {
        guard !drawing.bounds.isEmpty else { return }

        if let note = chapterNote {
            note.drawing = drawing
        } else {
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

    private var multiHighlightPaletteView: some View {
        VStack(spacing: 20) {
            Text("Highlight \(selectedVerses.count) Verse\(selectedVerses.count == 1 ? "" : "s")")
                .font(.headline)

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

            if selectedVersesHaveHighlights() {
                Button(role: .destructive) {
                    removeHighlightsFromSelectedVerses()
                } label: {
                    Label("Remove All Highlights", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
            }

            Button("Cancel") {
                showMultiHighlightPalette = false
            }
            .padding()
        }
        .padding()
        .presentationDetents([.medium])
    }

    private func selectedVersesHaveHighlights() -> Bool {
        for verseId in selectedVerses {
            if allHighlights.contains(where: { $0.verseId == verseId }) {
                return true
            }
        }
        return false
    }

    private func removeHighlightsFromSelectedVerses() {
        for verseId in selectedVerses {
            let highlights = allHighlights.filter { $0.verseId == verseId }
            for highlight in highlights {
                modelContext.delete(highlight)
            }
        }

        try? modelContext.save()

        showMultiHighlightPalette = false
        isMultiSelectMode = false
        selectedVerses.removeAll()
    }

    private func createMultiHighlight(color: HighlightColor) {
        for verseId in selectedVerses {
            if let verse = sortedVerses.first(where: { $0.id == verseId }) {
                let existingHighlight = allHighlights.first { highlight in
                    highlight.verseId == verse.id &&
                    highlight.startIndex == 0 &&
                    highlight.endIndex == verse.text.count &&
                    colorsMatch(highlight.highlightColor, color.color)
                }

                if let existingHighlight = existingHighlight {
                    modelContext.delete(existingHighlight)
                } else {
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
        }

        try? modelContext.save()

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

                Picker("Note Type", selection: $isHandwrittenMode) {
                    Label("Typed", systemImage: "keyboard").tag(false)
                    Label("Handwritten", systemImage: "pencil.tip.crop.circle").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if isHandwrittenMode {
                    CanvasViewRepresentable(canvasView: $noteCanvasView, drawing: $noteDrawing)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                } else {
                    TextEditor(text: $noteContent)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle("New Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        clearNoteEditor()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNote()
                    }
                    .disabled(noteTitle.isEmpty && noteContent.isEmpty && noteDrawing.bounds.isEmpty)
                }
            }
        }
        .presentationDetents([.large])
    }

    private func clearNoteEditor() {
        showingNoteEditor = false
        noteTitle = ""
        noteContent = ""
        noteDrawing = PKDrawing()
        noteCanvasView.drawing = PKDrawing()
        isHandwrittenMode = false
    }

    private func saveNote() {
        let note = Note(
            title: noteTitle.isEmpty ? "Untitled Note" : noteTitle,
            content: isHandwrittenMode ? "" : noteContent,
            drawing: isHandwrittenMode ? noteDrawing : PKDrawing(),
            verseReference: chapter.reference,
            isMarginNote: false,
            chapter: chapter,
            verse: nil
        )
        modelContext.insert(note)
        try? modelContext.save()

        clearNoteEditor()
    }

    private func copyWordToClipboard() {
        guard let word = selectedWord else { return }
        let copyText = """
        \(word.originalText) (\(word.transliteration))
        \(word.gloss)
        """
        UIPasteboard.general.string = copyText
    }

    private func openNoteEditorForWord() {
        guard let word = selectedWord else { return }
        noteTitle = "\(word.originalText) (\(word.transliteration))"
        noteContent = "Word: \(word.originalText)\nMeaning: \(word.gloss)\n\n"
        showInterlinearBottomSheet = false
        showingNoteEditor = true
    }

    private func openHighlightMenuForWord() {
        showInterlinearBottomSheet = false
        showUnifiedSelectionMenu = true
    }

    private func navigateToVerse(_ verseRef: VerseReference) {
        let bookName = verseRef.fullBookName
        let chapterNumber = verseRef.chapter

        let bookDescriptor = FetchDescriptor<Book>(
            predicate: #Predicate { book in
                book.name == bookName
            }
        )

        do {
            let books = try modelContext.fetch(bookDescriptor)
            guard let book = books.first else {
                print("Book not found: \(bookName)")
                return
            }

            guard let targetChapter = book.chapters.first(where: { $0.number == chapterNumber }) else {
                print("Chapter not found: \(chapterNumber)")
                return
            }

            showInterlinearBottomSheet = false
            onChapterChange(targetChapter)
        } catch {
            print("Error fetching book: \(error)")
        }
    }
}

// MARK: - Canvas View Representable for Note Editor
struct CanvasViewRepresentable: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    @Binding var drawing: PKDrawing

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawing = drawing
        canvasView.drawingPolicy = .anyInput
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.delegate = context.coordinator
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawing = drawing
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: CanvasViewRepresentable

        init(_ parent: CanvasViewRepresentable) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
}
