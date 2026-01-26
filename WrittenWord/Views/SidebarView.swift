//
//  SidebarView.swift
//  WrittenWord
//
//  Refactored: Chapters now shown inline with books
//
import SwiftUI
import SwiftData

struct SidebarView: View {
    @Query(sort: \Book.order) private var books: [Book]
    @Binding var selectedChapter: Chapter?
    
    @State private var selectedView: SidebarSection? = .bible
    @State private var expandedBook: Book?
    
    enum SidebarSection: Hashable {
        case bible
        case search
        case notebook
        case highlights
        case bookmarks
        case statistics
        case settings
        
        var title: String {
            switch self {
            case .bible: return "Bible"
            case .search: return "Search"
            case .notebook: return "Notebook"
            case .highlights: return "Highlights"
            case .bookmarks: return "Bookmarks"
            case .statistics: return "Statistics"
            case .settings: return "Settings"
            }
        }
        
        var icon: String {
            switch self {
            case .bible: return "book.closed.fill"
            case .search: return "magnifyingglass"
            case .notebook: return "note.text"
            case .highlights: return "highlighter"
            case .bookmarks: return "bookmark.fill"
            case .statistics: return "chart.bar.fill"
            case .settings: return "gear"
            }
        }
        
        var color: Color {
            switch self {
            case .bible: return .blue
            case .search: return .green
            case .notebook: return .orange
            case .highlights: return .yellow
            case .bookmarks: return .red
            case .statistics: return .purple
            case .settings: return .gray
            }
        }
    }
    
    var oldTestamentBooks: [Book] {
        books.filter { $0.testament == "OT" }
    }
    
    var newTestamentBooks: [Book] {
        books.filter { $0.testament == "NT" }
    }
    
    var body: some View {
        List(selection: $selectedView) {
            // Main navigation sections
            Section {
                NavigationLink(value: SidebarSection.bible) {
                    Label(SidebarSection.bible.title, systemImage: SidebarSection.bible.icon)
                        .foregroundStyle(SidebarSection.bible.color)
                }
                
                NavigationLink(destination: GlobalSearchView()) {
                    Label(SidebarSection.search.title, systemImage: SidebarSection.search.icon)
                        .foregroundStyle(SidebarSection.search.color)
                }
            }
            
            // Study tools
            Section("My Study") {
                NavigationLink(destination: NotebookView()) {
                    Label(SidebarSection.notebook.title, systemImage: SidebarSection.notebook.icon)
                        .foregroundStyle(SidebarSection.notebook.color)
                }
                
                NavigationLink(destination: HighlightsView()) {
                    Label(SidebarSection.highlights.title, systemImage: SidebarSection.highlights.icon)
                        .foregroundStyle(SidebarSection.highlights.color)
                }
                
                NavigationLink(destination: BookmarksView()) {
                    Label(SidebarSection.bookmarks.title, systemImage: SidebarSection.bookmarks.icon)
                        .foregroundStyle(SidebarSection.bookmarks.color)
                }
            }
            
            // Insights
            Section("Insights") {
                NavigationLink(destination: HighlightStatsView()) {
                    Label(SidebarSection.statistics.title, systemImage: SidebarSection.statistics.icon)
                        .foregroundStyle(SidebarSection.statistics.color)
                }
            }
            
            // Bible books with chapters
            if selectedView == .bible {
                BibleBooksSection(
                    title: "Old Testament",
                    books: oldTestamentBooks,
                    expandedBook: $expandedBook,
                    selectedChapter: $selectedChapter
                )
                
                BibleBooksSection(
                    title: "New Testament",
                    books: newTestamentBooks,
                    expandedBook: $expandedBook,
                    selectedChapter: $selectedChapter
                )
            }
            
            // Settings
            Section {
                NavigationLink(destination: SettingsView()) {
                    Label(SidebarSection.settings.title, systemImage: SidebarSection.settings.icon)
                        .foregroundStyle(SidebarSection.settings.color)
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Written Word")
    }
}

// MARK: - Bible Books Section Component
struct BibleBooksSection: View {
    let title: String
    let books: [Book]
    @Binding var expandedBook: Book?
    @Binding var selectedChapter: Chapter?
    
    var body: some View {
        Section {
            ForEach(books) { book in
                DisclosureGroup(
                    isExpanded: Binding(
                        get: { expandedBook?.id == book.id },
                        set: { isExpanded in
                            expandedBook = isExpanded ? book : nil
                        }
                    )
                ) {
                    // Chapters list
                    ForEach(book.chapters.sorted(by: { $0.number < $1.number })) { chapter in
                        Button {
                            selectedChapter = chapter
                        } label: {
                            HStack {
                                Text("Chapter \(chapter.number)")
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                // Verse count badge
                                Text("\(chapter.verses.count)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.secondary.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .background(
                            selectedChapter?.id == chapter.id ?
                            Color.accentColor.opacity(0.1) : Color.clear
                        )
                    }
                } label: {
                    HStack {
                        Text(book.name)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        Text("\(book.chapters.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        } header: {
            Text(title)
                .font(.subheadline.bold())
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Book.self,
        Chapter.self,
        Note.self,
        Highlight.self,
        Bookmark.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let genesis = Book(name: "Genesis", order: 1, testament: "OT")
    genesis.chapters = [Chapter(number: 1), Chapter(number: 2)]
    container.mainContext.insert(genesis)
    
    let matthew = Book(name: "Matthew", order: 40, testament: "NT")
    matthew.chapters = [Chapter(number: 1)]
    container.mainContext.insert(matthew)
    
    return NavigationStack {
        SidebarView(selectedChapter: .constant(nil))
    }
    .modelContainer(container)
}