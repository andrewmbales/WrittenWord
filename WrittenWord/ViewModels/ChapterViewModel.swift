//
//  ChapterViewModel.swift
//  WrittenWord
//
//  Separates business logic from UI for better testability and maintainability
//

import Foundation
import SwiftUI
import SwiftData
import PencilKit

@MainActor
@Observable
class ChapterViewModel {
    // MARK: - Dependencies
    private let modelContext: ModelContext
    let chapter: Chapter
    
    // MARK: - State
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
    
    // Search
    var searchText = ""
    
    // Bookmarks
    var showingBookmarkSheet = false
    var verseToBookmark: Verse?
    
    // Caches to avoid repeated heavy computations during render
    private var _sortedVerses: [Verse]?
    private var _previousChapter: Chapter?
    private var _nextChapter: Chapter?
    
    // MARK: - Computed Properties
    var sortedVerses: [Verse] {
        if let cached = _sortedVerses { return cached }
        let computed = chapter.verses.sorted { $0.number < $1.number }
        _sortedVerses = computed
        return computed
    }
    
    var filteredVerses: [Verse] {
        guard !searchText.isEmpty else { return sortedVerses }
        return sortedVerses.filter { verse in
            verse.text.localizedCaseInsensitiveContains(searchText) ||
            "\(verse.number)".contains(searchText)
        }
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
    
    // MARK: - Initialization
    init(chapter: Chapter, modelContext: ModelContext) {
        self.chapter = chapter
        self.modelContext = modelContext
        _sortedVerses = nil
        _previousChapter = nil
        _nextChapter = nil
    }
    
    // MARK: - Actions
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
        try? modelContext.save()
        
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
        try? modelContext.save()
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
        showHighlightMenu = true
    }
    
    private func resetSelection() {
        showHighlightMenu = false
        selectedRange = nil
        selectedText = ""
        selectedVerse = nil
    }
}

// MARK: - Supporting Types
enum AnnotationTool: String, CaseIterable {
    case none = "none"
    case pen = "pencil"
    case highlighter = "highlighter"
    case eraser = "eraser.fill"
    case lasso = "lasso"
    
    var icon: String {
        switch self {
        case .none: return "circle"
        default: return rawValue
        }
    }
}
