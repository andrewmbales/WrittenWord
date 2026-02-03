//
//  ChapterViewModel.swift
//  WrittenWord
//
//  Manages state and business logic for chapter display
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

    // MARK: - Canvas State (moved from View)
    var canvasView = PKCanvasView()
    var chapterNote: Note

    // MARK: - Annotation State
    var showingDrawing = false
    var selectedVerse: Verse?
    var showAnnotations = false
    var selectedTool: AnnotationTool = .none
    var previousTool: AnnotationTool = .pen  // Remember last selected tool
    var selectedColor: Color = .black
    var penWidth: CGFloat = 1.0
    var showingColorPicker = false

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
            // Cancel previous debounce task
            searchDebounceTask?.cancel()

            // Create new debounce task
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

    // MARK: - Cached Highlights (for performance)
    private var highlightsCache: [UUID: [Highlight]] = [:]
    
    // MARK: - Cached Verses (to avoid relationship invalidation issues)
    private var versesCache: [Verse] = []

    // MARK: - Computed Properties

    /// Verses sorted by number
    var sortedVerses: [Verse] {
        versesCache.sorted { $0.number < $1.number }
    }

    /// Verses filtered by search text
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

    /// Previous chapter in the book
    var previousChapter: Chapter? {
        guard let book = chapter.book else { return nil }
        let chapters = book.chapters.sorted { $0.number < $1.number }
        guard let currentIndex = chapters.firstIndex(where: { $0.id == chapter.id }),
              currentIndex > 0 else {
            return nil
        }
        return chapters[currentIndex - 1]
    }

    /// Next chapter in the book
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
        
        // Initialize with placeholder note - will be loaded properly in loadChapterNote()
        self.chapterNote = Note(
            title: "Annotations - \(chapter.reference)",
            content: "",
            drawing: PKDrawing(),
            verseReference: chapter.reference,
            isMarginNote: false,
            chapter: chapter,
            verse: nil
        )
        
        // Load highlights into cache for performance
        loadVerses()
        loadHighlights()
    }

    // MARK: - Data Loading
    
    /// Loads verses for this chapter fresh from the database
    private func loadVerses() {
        let chapterId = chapter.id
        let descriptor = FetchDescriptor<Verse>(
            predicate: #Predicate<Verse> { verse in
                verse.chapter?.id == chapterId
            },
            sortBy: [SortDescriptor(\.number)]
        )
        
        do {
            versesCache = try modelContext.fetch(descriptor)
        } catch {
            print("Error loading verses: \(error.localizedDescription)")
            // Fallback to relationship if fetch fails
            versesCache = Array(chapter.verses)
        }
    }

    /// Loads or creates the chapter note and initializes canvas
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
            } else {
                // Create new note
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
                
                // Save to ensure it persists
                try modelContext.save()
            }
        } catch {
            print("Error loading chapter note: \(error.localizedDescription)")
            // Still set a default note so the app doesn't crash
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

    /// Loads highlights for this chapter into cache
    private func loadHighlights() {
        // Get verse IDs for this chapter from our cached verses
        let verseIds = versesCache.map { $0.id }
        
        // Fetch all highlights
        let descriptor = FetchDescriptor<Highlight>()
        
        do {
            let allHighlights = try modelContext.fetch(descriptor)
            
            // Filter to only highlights whose verseId is in this chapter's verses
            // This avoids touching the verse relationship which can be invalidated
            let highlights = allHighlights.filter { highlight in
                verseIds.contains(highlight.verseId)
            }
            
            // Group by verse ID for fast lookup
            highlightsCache.removeAll()
            for highlight in highlights {
                let verseId = highlight.verseId
                highlightsCache[verseId, default: []].append(highlight)
            }
        } catch {
            print("Error loading highlights: \(error.localizedDescription)")
        }
    }

    /// Returns cached highlights for a specific verse (avoids repeated queries)
    func highlightsForVerse(_ verseId: UUID) -> [Highlight] {
        return highlightsCache[verseId] ?? []
    }

    // MARK: - Actions

    /// Creates a highlight for the selected text
    func createHighlight(color: HighlightColor) {
        guard let selectedVerse = selectedVerse,
              let range = selectedRange else {
            return
        }

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
        
        saveContext()
        resetSelection()
    }

    /// Bookmarks the current chapter
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

    /// Toggles annotation mode with proper state management
    func toggleAnnotations() {
        if showAnnotations {
            // Turning off - save and remember tool
            previousTool = selectedTool != .none ? selectedTool : previousTool
            selectedTool = .none
            Task {
                await saveAnnotations()
            }
        } else {
            // Turning on - restore previous tool
            selectedTool = previousTool
        }
        showAnnotations.toggle()
    }

    /// Saves the current canvas drawing to the note
    @MainActor
    func saveAnnotations() async {
        // Update the note's drawing
        chapterNote.drawing = canvasView.drawing
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving annotations: \(error.localizedDescription)")
            // TODO: Show user-facing error alert
        }
    }

    /// Clears all annotations from the drawing
    @MainActor
    func clearAnnotations() async {
        canvasView.drawing = PKDrawing()
        chapterNote.drawing = PKDrawing()
        
        do {
            try modelContext.save()
        } catch {
            print("Error clearing annotations: \(error.localizedDescription)")
        }
    }

    /// Converts AnnotationTool to DrawingTool for canvas
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

    /// Handles text selection - shows either interlinear lookup or highlight menu
    func selectTextForHighlight(verse: Verse, range: NSRange, text: String) {
        selectedVerse = verse
        selectedRange = range
        selectedText = text

        // Check if this is a single word with interlinear data
        if let word = WordLookupService.findWord(in: verse, for: range) {
            selectedWord = word
            showInterlinearLookup = true
        } else {
            showHighlightMenu = true
        }
    }

    // MARK: - Binding Helpers
    // These provide proper bindings for SwiftUI views to avoid observation issues

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

    func bindingForShowInterlinearLookup() -> Binding<Bool> {
        Binding(
            get: { self.showInterlinearLookup },
            set: { self.showInterlinearLookup = $0 }
        )
    }

    // MARK: - Private Methods

    /// Resets all selection state
    private func resetSelection() {
        showHighlightMenu = false
        showInterlinearLookup = false
        selectedRange = nil
        selectedText = ""
        selectedVerse = nil
        selectedWord = nil
    }

    /// Saves the model context with error handling
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Error saving context: \(error.localizedDescription)")
        }
    }

    /// Trigger for updating filtered verses (used by debounce)
    private func updateFilteredVerses() {
        // This is intentionally empty - the computed property handles filtering
        // This method exists only to trigger a view update after debouncing
    }
}
