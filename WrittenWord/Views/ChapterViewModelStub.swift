import SwiftUI
import SwiftData
import PencilKit
import Observation

@MainActor
@Observable
class ChapterViewModel {
    let chapter: Chapter
    var showingDrawing = false
    var selectedVerse: Verse?
    var showAnnotations = true
    var selectedTool: AnnotationTool = .none
    var selectedColor: Color = .black
    var penWidth: CGFloat = 1.0
    var canvasView = PKCanvasView()
    var showingColorPicker = false
    
    var showHighlightMenu = false
    var selectedText = ""
    var selectedRange: NSRange?
    var selectedHighlightColor: HighlightColor = .yellow
    
    var searchText = ""
    
    var showingBookmarkSheet = false
    var verseToBookmark: Verse?
    
    init(chapter: Chapter, modelContext: ModelContext) {
        self.chapter = chapter
        // modelContext is intentionally unused here; kept to match call sites.
    }
    
    var sortedVerses: [Verse] { chapter.verses.sorted { $0.number < $1.number } }
    var filteredVerses: [Verse] { searchText.isEmpty ? sortedVerses : sortedVerses.filter { $0.text.localizedCaseInsensitiveContains(searchText) || "\( $0.number )".contains(searchText) } }
    
    var previousChapter: Chapter? {
        guard let book = chapter.book else { return nil }
        let chapters = book.chapters.sorted { $0.number < $1.number }
        guard let idx = chapters.firstIndex(of: chapter), idx > 0 else { return nil }
        return chapters[idx - 1]
    }
    var nextChapter: Chapter? {
        guard let book = chapter.book else { return nil }
        let chapters = book.chapters.sorted { $0.number < $1.number }
        guard let idx = chapters.firstIndex(of: chapter), idx < chapters.count - 1 else { return nil }
        return chapters[idx + 1]
    }
    
    func createHighlight(color: HighlightColor) {
        selectedHighlightColor = color
        // If we have a selected verse and range, present the highlight UI state.
        if selectedVerse != nil, selectedRange != nil {
            showHighlightMenu = true
        }
    }
    func bookmarkChapter() {
        showingBookmarkSheet = true
        verseToBookmark = nil
    }
    func selectTextForHighlight(verse: Verse, range: NSRange, text: String) {
        selectedVerse = verse
        selectedRange = range
        selectedText = text
        showHighlightMenu = true
    }
}

