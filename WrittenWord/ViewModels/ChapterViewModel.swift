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

@MainActor
@Observable
class ChapterViewModel {
    private let modelContext: ModelContext
    let chapter: Chapter

    // MARK: - Annotation State
    var showingDrawing = false
    var selectedVerse: Verse?
    var showAnnotations = true
    var selectedTool: AnnotationTool = .none
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

    // MARK: - Computed Properties

    /// Verses sorted by number
    var sortedVerses: [Verse] {
        chapter.verses.sorted { $0.number < $1.number }
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
    }

    deinit {
        // Clean up any running tasks
        searchDebounceTask?.cancel()
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

    /// Clears all annotations from the drawing
    func clearAnnotations(drawing: inout PKDrawing) {
        drawing = PKDrawing()
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
