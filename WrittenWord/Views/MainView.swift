//
//  MainView.swift - FIXED
//  WrittenWord
//
//  Prevents sliding by properly managing NavigationSplitView layout
//

import SwiftUI
import SwiftData

struct MainView: View {
    @State private var selectedChapter: Chapter?
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            SidebarView(selectedChapter: $selectedChapter)
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
        } detail: {
            // Detail - This structure prevents the sliding issue
            ZStack {
                if let chapter = selectedChapter {
                    ChapterView(chapter: chapter) { newChapter in
                        selectedChapter = newChapter
                    }
                    .id(chapter.id) // Force view refresh on chapter change
                    .transition(.opacity) // Smooth transition
                } else {
                    emptyStateView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Key fix: Explicitly set the detail column width
            .navigationSplitViewColumnWidth(min: 600, ideal: 900)
        }
        .navigationSplitViewStyle(.balanced)
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "Select a Chapter",
            systemImage: "book.pages.fill",
            description: Text("Choose a chapter from the sidebar to begin reading")
        )
    }
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