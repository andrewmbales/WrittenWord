//
//  ChapterViewModel.swift
//  WrittenWord
//
//  OPTIMIZED: Improved caching, performance, and memory management
//

import Foundation
import SwiftUI
import Observation
import SwiftData
import PencilKit

@Observable
class ChapterViewModel {
    private let modelContext: ModelContext
    let chapter: Chapter

    // MARK: - Canvas State
    var canvasView = PKCanvasView()
    var chapterNote: Note

    // MARK: - Annotation State
    var showingDrawing = false
    var selectedVerse: Verse?
    var showAnnotations = false
    var selectedTool: AnnotationTool = .none
    var previousTool: AnnotationTool = .pen
    var selectedColor: Color = .black
    var penWidth: CGFloat = 1.0
    var eraserType: EraserType = .partial
    var showingColorPicker = false

    // MARK: - Interlinear State (NEW - ADD THIS SECTION)
    var showInterlinear = false
    
    var interlinearLanguage: String {
        guard let testament = chapter.book?.testament else { return "Original" }
        return testament == "NT" ? "Greek" : "Hebrew"
    }

    /// The character displayed on the interlinear toggle button
    var interlinearCharacter: String {
        guard let testament = chapter.book?.testament else { return "α" }
        return testament == "NT" ? "α" : "א"
    }
    
    // MARK: - Highlighting State
    var showHighlightMenu = false
    var selectedText = ""
    var selectedRange: NSRange?
    var selectedHighlightColor: HighlightColor = .yellow

    // MARK: - Interlinear Word Lookup
    var showInterlinearLookup = false
    var selectedWord: Word?

    // MARK: - Search State
    var searchText = "" {
        didSet {
            searchDebounceTask?.cancel()
            searchDebounceTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                self?.updateFilteredVerses()
            }
        }
    }

    private var searchDebounceTask: Task<Void, Never>?

    // MARK: - Bookmark State
    var showingBookmarkSheet = false
    var verseToBookmark: Verse?

    // MARK: - Remove Highlights State
    var showRemoveHighlightsConfirmation = false

    // MARK: - Performance Caches
    private var highlightsCache: [UUID: [Highlight]] = [:]
    private var versesCache: [Verse] = []

    // MARK: - Computed Properties

    var sortedVerses: [Verse] {
        versesCache.sorted { $0.number < $1.number }
    }

    var filteredVerses: [Verse] {
        guard !searchText.isEmpty else {
            return sortedVerses
        }

        let lowercased = searchText.lowercased()
        return sortedVerses.filter { verse in
            verse.text.localizedCaseInsensitiveContains(lowercased) ||
            "\(verse.number)".contains(lowercased)
        }
    }

    var previousChapter: Chapter? {
        guard let book = chapter.book else { return nil }
        let chapters = book.chapters.sorted { $0.number < $1.number }
        guard let currentIndex = chapters.firstIndex(where: { $0.id == chapter.id }),
              currentIndex > 0 else {
            return nil
        }
        return chapters[currentIndex - 1]
    }

    var nextChapter: Chapter? {
        guard let book = chapter.book else { return nil }
        let chapters = book.chapters.sorted { $0.number < $1.number }
        guard let currentIndex = chapters.firstIndex(where: { $0.id == chapter.id }),
              currentIndex < chapters.count - 1 else {
            return nil
        }
        return chapters[currentIndex + 1]
    }

    // MARK: - Initialization

    init(chapter: Chapter, modelContext: ModelContext) {
        self.chapter = chapter
        self.modelContext = modelContext
        
        self.chapterNote = Note(
            title: "Annotations - \(chapter.reference)",
            content: "",
            drawing: PKDrawing(),
            verseReference: chapter.reference,
            isMarginNote: false,
            chapter: chapter,
            verse: nil
        )
        
        #if DEBUG
        print("📊 ChapterViewModel: Initializing for \(chapter.reference)")
        #endif
        
        loadVerses()
        loadHighlights()
    }

    // MARK: - Data Loading (OPTIMIZED)
    
    /// Batch loads all verses for this chapter
    private func loadVerses() {
        guard versesCache.isEmpty else {
            #if DEBUG
            print("📊 Using cached verses (\(versesCache.count))")
            #endif
            return
        }

        // Use the relationship directly — more reliable than a predicate
        // on an optional relationship (verse.chapter?.id) which SwiftData
        // can sometimes fail to resolve for all rows.
        versesCache = chapter.verses.sorted { $0.number < $1.number }
        #if DEBUG
        print("📊 Loaded \(versesCache.count) verses for \(chapter.reference)")
        #endif
    }

    /// Batch loads all highlights for this chapter (OPTIMIZED)
    private func loadHighlights() {
        let verseIds = versesCache.map { $0.id }
        
        let descriptor = FetchDescriptor<Highlight>()
        
        do {
            let allHighlights = try modelContext.fetch(descriptor)
            let highlights = allHighlights.filter { verseIds.contains($0.verseId) }
            
            highlightsCache.removeAll()
            for highlight in highlights {
                highlightsCache[highlight.verseId, default: []].append(highlight)
            }
            
            #if DEBUG
            print("📊 Loaded \(highlights.count) highlights across \(highlightsCache.count) verses")
            #endif
        } catch {
            print("❌ Error loading highlights: \(error.localizedDescription)")
        }
    }

    /// Returns cached highlights for a verse (O(1) lookup)
    func highlightsForVerse(_ verseId: UUID) -> [Highlight] {
        return highlightsCache[verseId] ?? []
    }

    /// Loads or creates the chapter note
    @MainActor
    func loadChapterNote() async {
        let chapterId = chapter.id
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate<Note> { note in
                note.chapter?.id == chapterId && note.verse == nil
            }
        )
        
        do {
            if let existingNote = try modelContext.fetch(descriptor).first {
                self.chapterNote = existingNote
                self.canvasView.drawing = existingNote.drawing
                #if DEBUG
                print("📊 Loaded existing chapter note")
                #endif
            } else {
                let newNote = Note(
                    title: "Annotations - \(chapter.reference)",
                    content: "",
                    drawing: PKDrawing(),
                    verseReference: chapter.reference,
                    isMarginNote: false,
                    chapter: chapter,
                    verse: nil
                )
                modelContext.insert(newNote)
                self.chapterNote = newNote
                try modelContext.save()
                #if DEBUG
                print("📊 Created new chapter note")
                #endif
            }
        } catch {
            print("❌ Error loading chapter note: \(error.localizedDescription)")
            self.chapterNote = Note(
                title: "Annotations - \(chapter.reference)",
                content: "",
                drawing: PKDrawing(),
                verseReference: chapter.reference,
                isMarginNote: false,
                chapter: chapter,
                verse: nil
            )
        }
    }

    // MARK: - Actions

    func createHighlight(color: HighlightColor) {
        guard let selectedVerse = selectedVerse,
              let range = selectedRange else {
            #if DEBUG
            print("❌ Cannot create highlight - missing verse or range")
            #endif
            return
        }
        
        #if DEBUG
        print("✅ Creating highlight - verse: \(selectedVerse.number), range: \(range), color: \(color.rawValue)")
        #endif

        let highlight = Highlight(
            verseId: selectedVerse.id,
            startIndex: range.location,
            endIndex: range.location + range.length,
            color: color.color,
            text: selectedText,
            verse: selectedVerse
        )

        modelContext.insert(highlight)
        
        // Update cache immediately
        highlightsCache[selectedVerse.id, default: []].append(highlight)
        
        // CRITICAL: Save the context
        do {
            try modelContext.save()
            #if DEBUG
            print("✅ Highlight saved successfully")
            #endif
        } catch {
            print("❌ Error saving highlight: \(error.localizedDescription)")
        }
        
        resetSelection()
    }

    /// Remove highlights overlapping with the current selection
    func removeHighlightAtSelection() {
        guard let selectedVerse = selectedVerse,
              let range = selectedRange else {
            resetSelection()
            return
        }

        let verseHighlights = highlightsCache[selectedVerse.id] ?? []

        // Find highlights that overlap with the selection
        let overlapping = verseHighlights.filter { highlight in
            let hStart = highlight.startIndex
            let hEnd = highlight.endIndex
            let sStart = range.location
            let sEnd = range.location + range.length
            return hStart < sEnd && hEnd > sStart
        }

        for highlight in overlapping {
            modelContext.delete(highlight)
        }

        if !overlapping.isEmpty {
            let removedIds = Set(overlapping.map { $0.id })
            highlightsCache[selectedVerse.id]?.removeAll { removedIds.contains($0.id) }
            saveContext()
        }

        resetSelection()
    }

    func removeAllHighlightsInChapter() {
        let verseIds = versesCache.map { $0.id }

        let descriptor = FetchDescriptor<Highlight>()

        do {
            let allHighlights = try modelContext.fetch(descriptor)
            let chapterHighlights = allHighlights.filter { verseIds.contains($0.verseId) }

            for highlight in chapterHighlights {
                modelContext.delete(highlight)
            }

            try modelContext.save()
            highlightsCache.removeAll()

            #if DEBUG
            print("✅ Removed \(chapterHighlights.count) highlights from chapter")
            #endif
        } catch {
            print("❌ Error removing highlights: \(error.localizedDescription)")
        }
    }

    var chapterHighlightCount: Int {
        highlightsCache.values.reduce(0) { $0 + $1.count }
    }

    func bookmarkChapter() {
        let bookmark = Bookmark(
            title: "",
            chapter: chapter,
            category: BookmarkCategory.general.rawValue,
            color: BookmarkCategory.general.color
        )
        modelContext.insert(bookmark)
        saveContext()
    }

    func toggleAnnotations() {
        if showAnnotations {
            previousTool = selectedTool != .none ? selectedTool : .pen
            selectedTool = .none
            canvasView.tool = PKInkingTool(.pen, color: .clear)
            chapterNote.drawing = canvasView.drawing
            saveContext()
        } else {
            selectedTool = previousTool
            updateCanvasTool()
        }
        showAnnotations.toggle()
    }

    func undoAnnotation() {
        canvasView.undoManager?.undo()
    }

    func redoAnnotation() {
        canvasView.undoManager?.redo()
    }

    // Add this method to ChapterViewModel_Optimized.swift

    // Converts AnnotationTool to DrawingTool for canvas compatibility
    func convertToDrawingTool() -> DrawingTool {
        switch selectedTool {
        case .none:
            return .none
        case .pen:
            return .pen
        case .highlighter:
            return .highlighter
        case .eraser:
            return .eraser
        case .lasso:
            return .lasso
        }
    }
    
    func updateCanvasTool() {
        switch selectedTool {
        case .pen:
            let color = UIColor(selectedColor)
            canvasView.tool = PKInkingTool(.pen, color: color, width: penWidth)
        case .highlighter:
            let color = UIColor(selectedColor)
            canvasView.tool = PKInkingTool(.marker, color: color, width: penWidth * 5)
        case .eraser:
            switch eraserType {
            case .partial:
                canvasView.tool = PKEraserTool(.bitmap)
            case .object:
                canvasView.tool = PKEraserTool(.vector)
            }
        case .lasso:
            canvasView.tool = PKLassoTool()
        case .none:
            canvasView.tool = PKInkingTool(.pen, color: .clear)
        }
    }

    /// Called on short tap – selects the entire verse for highlighting
    func selectVerseForHighlight(verse: Verse) {
        selectedVerse = verse
        selectedRange = NSRange(location: 0, length: verse.text.count)
        selectedText = verse.text
        showHighlightMenu = true
    }

    /// Called on long press or drag-select – checks interlinear first, then falls back to highlight
    func selectTextForHighlight(verse: Verse, range: NSRange, text: String) {
        #if DEBUG
        print("🎯 Text selected for highlight")
        print("   Verse: \(verse.chapter?.book?.name ?? "") \(verse.chapter?.number ?? 0):\(verse.number)")
        print("   Range: \(range.location)-\(range.location + range.length)")
        print("   Text: \(text)")
        #endif

        selectedVerse = verse
        selectedRange = range
        selectedText = text

        // If interlinear mode is active, try word lookup first
        if showInterlinear, let word = WordLookupService.findWord(in: verse, for: range) {
            selectedWord = word
            showInterlinearLookup = true
            return
        }

        // Fallback: show highlight menu
        showHighlightMenu = true
    }

    // MARK: - Binding Helpers

    func bindingForSearchText() -> Binding<String> {
        Binding(
            get: { self.searchText },
            set: { self.searchText = $0 }
        )
    }

    func bindingForSelectedTool() -> Binding<AnnotationTool> {
        Binding(
            get: { self.selectedTool },
            set: { self.selectedTool = $0 }
        )
    }

    func bindingForSelectedColor() -> Binding<Color> {
        Binding(
            get: { self.selectedColor },
            set: { self.selectedColor = $0 }
        )
    }

    func bindingForPenWidth() -> Binding<CGFloat> {
        Binding(
            get: { self.penWidth },
            set: { self.penWidth = $0 }
        )
    }

    func bindingForShowingColorPicker() -> Binding<Bool> {
        Binding(
            get: { self.showingColorPicker },
            set: { self.showingColorPicker = $0 }
        )
    }

    func bindingForSelectedHighlightColor() -> Binding<HighlightColor> {
        Binding(
            get: { self.selectedHighlightColor },
            set: { self.selectedHighlightColor = $0 }
        )
    }

    func bindingForShowingDrawing() -> Binding<Bool> {
        Binding(
            get: { self.showingDrawing },
            set: { self.showingDrawing = $0 }
        )
    }

    func bindingForVerseToBookmark() -> Binding<Verse?> {
        Binding(
            get: { self.verseToBookmark },
            set: { self.verseToBookmark = $0 }
        )
    }

    func bindingForCanvasView() -> Binding<PKCanvasView> {
        Binding(
            get: { self.canvasView },
            set: { self.canvasView = $0 }
        )
    }

    func bindingForShowInterlinear() -> Binding<Bool> {
        Binding(
            get: { self.showInterlinear },
            set: { self.showInterlinear = $0 }
        )
    }
    
    func bindingForShowingBookmarkSheet() -> Binding<Bool> {
        Binding(
            get: { self.showingBookmarkSheet },
            set: { self.showingBookmarkSheet = $0 }
        )
    }

    func bindingForChapterNoteDrawing() -> Binding<PKDrawing> {
        Binding(
            get: { self.chapterNote.drawing },
            set: {
                self.chapterNote.drawing = $0
                // Auto-save on drawing change
                do {
                    try self.modelContext.save()
                } catch {
                    print("❌ Error saving drawing: \(error.localizedDescription)")
                }
            }
        )
    }

    // MARK: - Private Methods

    private func resetSelection() {
        showHighlightMenu = false
        showInterlinearLookup = false
        selectedRange = nil
        selectedText = ""
        selectedVerse = nil
        selectedWord = nil
    }

    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("❌ Error saving context: \(error.localizedDescription)")
        }
    }

    private func updateFilteredVerses() {
        // Intentionally empty - computed property handles filtering
    }
}

