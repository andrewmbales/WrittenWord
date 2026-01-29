//
//  MainView.swift
//  WrittenWord
//
//  ENHANCED: Search as detail view instead of sheet
//

import SwiftUI
import SwiftData

struct MainView: View {
    @State private var selectedChapter: Chapter?
    @State private var showingSearch = false
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            SidebarView(
                selectedChapter: $selectedChapter,
                showingSearch: $showingSearch
            )
            .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 400)
        } detail: {
            // Detail view - either Chapter or Search
            Group {
                if showingSearch {
                    GlobalSearchView()
                        .onDisappear {
                            showingSearch = false
                        }
                } else if let chapter = selectedChapter {
                    ChapterView(chapter: chapter) { newChapter in
                        selectedChapter = newChapter
                    }
                    .id(chapter.id)
                } else {
                    emptyStateView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationSplitViewColumnWidth(min: 600, ideal: 900)
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: selectedChapter) { _, newValue in
            // When selecting a chapter, hide search
            if newValue != nil {
                showingSearch = false
            }
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
