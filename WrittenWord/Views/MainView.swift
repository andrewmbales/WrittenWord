//
//  MainView.swift - FIXED
//  WrittenWord
//
//  Properly handles NavigationSplitView with navigationDestination
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
                    ChapterView_Optimized(chapter: chapter) { newChapter in
                        print("🔄 [MAIN] Chapter change callback - FROM: \(chapter.book?.name ?? "Unknown") \(chapter.number) TO: \(newChapter.book?.name ?? "Unknown") \(newChapter.number)")
                        selectedChapter = newChapter
                        print("✅ [MAIN] selectedChapter updated: \(selectedChapter?.book?.name ?? "nil") \(selectedChapter?.number ?? -1)")
                    }
                    .id(chapter.id)
                    .transition(.opacity)
                } else {
                    emptyStateView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            // Key fix: Explicitly set the detail column width
            .navigationSplitViewColumnWidth(min: 600, ideal: 900)
            // CRITICAL: Add navigationDestination here to handle Chapter navigation
            .navigationDestination(for: Chapter.self) { chapter in
                ChapterView_Optimized(chapter: chapter) { newChapter in
                    print("🔄 [MAIN] NavigationDestination callback: \(newChapter.book?.name ?? "Unknown") \(newChapter.number)")
                    selectedChapter = newChapter
                    print("✅ [MAIN] NavigationDestination updated selectedChapter: \(selectedChapter?.book?.name ?? "nil") \(selectedChapter?.number ?? -1)")
                }
                .onAppear {
                    print("🧭 [MAIN] NavigationDestination triggered: \(chapter.book?.name ?? "Unknown") \(chapter.number) (ID: \(chapter.id))")
                    print("🧭 [MAIN] Current selectedChapter before navigation: \(selectedChapter?.book?.name ?? "nil") \(selectedChapter?.number ?? -1)")
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
        .onAppear {
            print("🏠 [MAIN] MainView appeared - selectedChapter: \(selectedChapter?.book?.name ?? "nil") \(selectedChapter?.number ?? -1)")
        }
        .onChange(of: selectedChapter) { oldValue, newValue in
            print("🏠 [MAIN] selectedChapter changed FROM: \(oldValue?.book?.name ?? "nil") \(oldValue?.number ?? -1) TO: \(newValue?.book?.name ?? "nil") \(newValue?.number ?? -1)")
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
