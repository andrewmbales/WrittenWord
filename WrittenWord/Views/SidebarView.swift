//
//  SidebarView.swift - OPTIMIZED
//  WrittenWord
//
//  Streamlined with compact chapter buttons
//

import SwiftUI
import SwiftData

struct SidebarView: View {
    @Query(sort: \Book.order) private var books: [Book]
    @Binding var selectedChapter: Chapter?
    
    @State private var selectedView: SidebarSection? = .bible
    @State private var expandedBook: Book?
    @State private var isOldTestamentExpanded: Bool = false
    @State private var isNewTestamentExpanded: Bool = false
    
    enum SidebarSection: Hashable {
        case bible, search, notebook, highlights, bookmarks, statistics, settings
        
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
            // Main navigation
            Section ("Bible"){
                NavigationLink(destination: GlobalSearchView()) {
                    Label(SidebarSection.search.title, systemImage: SidebarSection.search.icon)
                        .foregroundStyle(SidebarSection.search.color)
                }
                
                NavigationLink(value: SidebarSection.bible) {
                    Label(SidebarSection.bible.title, systemImage: SidebarSection.bible.icon)
                        .foregroundStyle(SidebarSection.bible.color)
                }
                
                // Bible books with chapters - directly under Bible button
                DisclosureGroup("Old Testament", isExpanded: $isOldTestamentExpanded) {
                    BibleBooksSection(
                        title: "",
                        books: oldTestamentBooks,
                        expandedBook: $expandedBook,
                        selectedChapter: $selectedChapter
                    )
                }
                
                DisclosureGroup("New Testament", isExpanded: $isNewTestamentExpanded) {
                    BibleBooksSection(
                        title: "",
                        books: newTestamentBooks,
                        expandedBook: $expandedBook,
                        selectedChapter: $selectedChapter
                    )
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

// MARK: - Bible Books Section - OPTIMIZED
struct BibleBooksSection: View {
    let title: String
    let books: [Book]
    @Binding var expandedBook: Book?
    @Binding var selectedChapter: Chapter?
    
    // Grid layout for compact chapter buttons
    private let columns = [
        GridItem(.adaptive(minimum: 40, maximum: 50), spacing: 8)
    ]
    
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
                    // COMPACT CHAPTER GRID - Numbers only, left-justified
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                        ForEach(book.chapters.sorted(by: { $0.number < $1.number })) { chapter in
                            CompactChapterButton(
                                chapter: chapter,
                                isSelected: selectedChapter?.id == chapter.id
                            ) {
                                selectedChapter = chapter
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.leading, 8)
                } label: {
                    HStack {
                        Text(book.name)
                            .font(.subheadline)
                        
                        Spacer()
                        
                        // Chapter count badge
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
            if !title.isEmpty {
                Text(title)
                    .font(.subheadline.bold())
            }
        }
    }
}

// MARK: - Compact Chapter Button (for Sidebar)
struct CompactChapterButton: View {
    let chapter: Chapter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(chapter.number)")
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 40, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
                )
        }
        .buttonStyle(.plain)
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
    genesis.chapters = (1...50).map { Chapter(number: $0, book: genesis) }
    container.mainContext.insert(genesis)
    
    let matthew = Book(name: "Matthew", order: 40, testament: "NT")
    matthew.chapters = (1...28).map { Chapter(number: $0, book: matthew) }
    container.mainContext.insert(matthew)
    
    return NavigationStack {
        SidebarView(selectedChapter: .constant(nil))
    }
    .modelContainer(container)
}