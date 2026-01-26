//
//  MainView.swift - FIXED
//  WrittenWord
//
//  Properly constrains detail view to prevent sliding
//
import SwiftUI
import SwiftData

struct MainView: View {
    @State private var selectedChapter: Chapter?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @AppStorage("notePosition") private var notePosition: NotePosition = .right
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar: Books and Chapters
            SidebarView(selectedChapter: $selectedChapter)
                .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } detail: {
            // Detail: Properly constrained to prevent sliding
            detailContent
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .navigationSplitViewStyle(.balanced)
    }
    
    @ViewBuilder
    private var detailContent: some View {
        if let chapter = selectedChapter {
            ChapterView(
                chapter: chapter,
                onChapterChange: { newChapter in
                    selectedChapter = newChapter
                }
            )
            .id(chapter.id)
        } else {
            emptyStateView
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "Select a Chapter",
            systemImage: "book.pages.fill",
            description: Text("Choose a chapter from the sidebar to begin reading")
        )
    }
}

// MARK: - Supporting Types
enum NotePosition: String, CaseIterable {
    case left = "left"
    case right = "right"
    
    var displayName: String {
        switch self {
        case .left: return "Left"
        case .right: return "Right"
        }
    }
}

extension Notification.Name {
    static let showNotesColumn = Notification.Name("showNotesColumn")
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Book.self,
        Chapter.self,
        Verse.self,
        Note.self,
        Highlight.self,
        Bookmark.self,
        configurations: config
    )
    
    let book = Book(name: "Genesis", order: 1, testament: "OT")
    let chapter = Chapter(number: 1, book: book)
    let verse1 = Verse(number: 1, text: "In the beginning God created the heaven and the earth.", chapter: chapter)
    
    container.mainContext.insert(book)
    container.mainContext.insert(chapter)
    container.mainContext.insert(verse1)
    
    return MainView()
        .modelContainer(container)
}