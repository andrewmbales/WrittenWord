//
//  MainView.swift - DEFINITIVE FIX
//  WrittenWord
//
//  This version uses multiple strategies to prevent text sliding
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
            // Detail: Wrapped to ensure proper positioning
            detailViewWrapper
        }
        .navigationSplitViewStyle(.balanced)
    }
    
    @ViewBuilder
    private var detailViewWrapper: some View {
        ZStack(alignment: .topLeading) {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            if let chapter = selectedChapter {
                ScrollView {
                    ChapterView(
                        chapter: chapter,
                        onChapterChange: { newChapter in
                            selectedChapter = newChapter
                        }
                    )
                    .id(chapter.id)
                    .padding(.horizontal, 20)  // Add explicit padding
                    .padding(.top, 20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                emptyStateView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "Select a Chapter",
            systemImage: "book.pages.fill",
            description: Text("Choose a chapter from the sidebar to begin reading")
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
