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
    @AppStorage("colorTheme") private var colorTheme: ColorTheme = .system

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            SidebarView(
                selectedChapter: $selectedChapter,
                showingSearch: $showingSearch,
                onNavigationAction: {
                    // Auto-collapse sidebar when navigation buttons are tapped
                    withAnimation {
                        columnVisibility = .detailOnly
                    }
                }
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
                    ChapterView(
                        chapter: chapter,
                        onChapterChange: { newChapter in
                            selectedChapter = newChapter
                        },
                        onVerseInteraction: {
                            // Auto-collapse sidebar when user interacts with verses
                            withAnimation {
                                columnVisibility = .detailOnly
                            }
                        }
                    )
                    .id(chapter.id)
                } else {
                    emptyStateView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationSplitViewColumnWidth(min: 600, ideal: 900)
        }
        .navigationSplitViewStyle(.balanced)
        .preferredColorScheme(colorTheme == .dark ? .dark : colorTheme == .light ? .light : nil)
        .background(colorTheme.backgroundColor)
        .onChange(of: selectedChapter) { _, newValue in
            // When selecting a chapter, hide search and collapse sidebar
            if newValue != nil {
                showingSearch = false
                withAnimation {
                    columnVisibility = .detailOnly
                }
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
