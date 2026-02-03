//
//  ChapterViewModel_Optimized.swift
//  WrittenWord
//
//  PERFORMANCE IMPROVEMENTS:
//  1. Cached queries with predicates
//  2. Debounced search
//  3. Lazy property loading
//

import Foundation
import SwiftUI
import SwiftData
import PencilKit

@MainActor
@Observable
class ChapterViewModel_Optimized {
    private let modelContext: ModelContext
    let chapter: Chapter
    
    // State
    var showingDrawing = false
    var selectedVerse: Verse?
    var showAnnotations = true
    var selectedTool: AnnotationTool = .none
    var selectedColor: Color = .black
    var penWidth: CGFloat = 1.0
    var canvasView = PKCanvasView()
    var showingColorPicker = false
    
    // Highlighting
    var showHighlightMenu = false
    var selectedText = ""
    var selectedRange: NSRange?
    var selectedHighlightColor: HighlightColor = .yellow

    // Interlinear Word Lookup
    var showInterlinearLookup = false
    var selectedWord: Word?
    
    // Search with debouncing
    private var _searchText = ""
    var searchText: String {
        get { _searchText }
        set {
            _searchText = newValue
            // Debounce search
            searchDebounceTask?.cancel()
            searchDebounceTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
                if !Task.isCancelled {
                    invalidateFilteredVerses()
                }
            }
        }
    }
    private var searchDebounceTask: Task<Void, Never>?
    
    // Bookmarks
    var showingBookmarkSheet = false
    var verseToBookmark: Verse?
    
    // OPTIMIZED: Lazy-loaded, cached properties
    private var _sortedVerses: [Verse]?
    private var _filteredVerses: [Verse]?
    private var _previousChapter: Chapter?
    private var _nextChapter: Chapter?
    
    var sortedVerses: [Verse] {
        if let cached = _sortedVerses { return cached }
        let computed = chapter.verses.sorted { $0.number < $1.number }
        _sortedVerses = computed
        return computed
    }
    
    var filteredVerses: [Verse] {
        if let cached = _filteredVerses { return cached }
        
        guard !searchText.isEmpty else {
            _filteredVerses = sortedVerses
            return sortedVerses
        }
        
        let lowercased = searchText.lowercased()
        let filtered = sortedVerses.filter { verse in
            verse.text.localizedCaseInsensitiveContains(lowercased) ||
            "\(verse.number)".contains(lowercased)
        }
        _filteredVerses = filtered
        return filtered
    }
    
    var previousChapter: Chapter? {
        if let cached = _previousChapter { return cached }
        guard let book = chapter.book else { return nil }
        let chapters = book.chapters.sorted { $0.number < $1.number }
        guard let currentIndex = chapters.firstIndex(of: chapter), currentIndex > 0 else {
            return nil
        }
        let prev = chapters[currentIndex - 1]
        _previousChapter = prev
        return prev
    }
    
    var nextChapter: Chapter? {
        if let cached = _nextChapter { return cached }
        guard let book = chapter.book else { return nil }
        let chapters = book.chapters.sorted { $0.number < $1.number }
        guard let currentIndex = chapters.firstIndex(of: chapter),
              currentIndex < chapters.count - 1 else {
            return nil
        }
        let next = chapters[currentIndex + 1]
        _nextChapter = next
        return next
    }
    
    init(chapter: Chapter, modelContext: ModelContext) {
        self.chapter = chapter
        self.modelContext = modelContext
    }
    
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
        
        // Batch save to reduce disk I/O
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms
            try? modelContext.save()
        }
        
        resetSelection()
    }
    
    func bookmarkChapter() {
        let bookmark = Bookmark(
            title: "",
            chapter: chapter,
            category: BookmarkCategory.general.rawValue,
            color: BookmarkCategory.general.color
        )
        modelContext.insert(bookmark)
        
        // Batch save
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            try? modelContext.save()
        }
    }
    
    func clearAnnotations(canvasView: PKCanvasView, chapterNote: Note?) {
        canvasView.drawing = PKDrawing()
        if let chapterNote = chapterNote {
            chapterNote.drawing = PKDrawing()
            try? modelContext.save()
        }
    }
    
    func selectTextForHighlight(verse: Verse, range: NSRange, text: String) {
        selectedVerse = verse
        selectedRange = range
        selectedText = text

        // Check if this is a single word selection and if we have interlinear data
        if let word = WordLookupService.findWord(in: verse, for: range) {
            // Show interlinear lookup for single word
            selectedWord = word
            showInterlinearLookup = true
        } else {
            // Show highlight menu for multi-word selection or no interlinear data
            showHighlightMenu = true
        }
    }
    
    private func resetSelection() {
        showHighlightMenu = false
        showInterlinearLookup = false
        selectedRange = nil
        selectedText = ""
        selectedVerse = nil
        selectedWord = nil
    }
    
    private func invalidateFilteredVerses() {
        _filteredVerses = nil
    }
}