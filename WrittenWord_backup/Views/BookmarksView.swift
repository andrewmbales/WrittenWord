//
//  BookmarksView.swift
//  WrittenWord
//
//  Phase 2: Bookmarks Management
//
import SwiftUI
import SwiftData

struct BookmarksView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Bookmark.createdAt, order: .reverse) private var bookmarks: [Bookmark]
    
    @State private var searchText = ""
    @State private var selectedCategory: BookmarkCategory?
    @State private var showingAddBookmark = false
    @State private var groupBy: GroupingOption = .category
    @State private var showingDeleteConfirmation = false
    @State private var bookmarkToDelete: Bookmark?
    
    enum GroupingOption: String, CaseIterable {
        case category = "Category"
        case date = "Date"
        case book = "Book"
        case pinned = "Pinned First"
        
        var icon: String {
            switch self {
            case .category: return "folder"
            case .date: return "calendar"
            case .book: return "book.closed"
            case .pinned: return "pin.fill"
            }
        }
    }
    
    var filteredBookmarks: [Bookmark] {
        var results = bookmarks
        
        // Filter by search
        if !searchText.isEmpty {
            results = results.filter { bookmark in
                bookmark.displayTitle.localizedCaseInsensitiveContains(searchText) ||
                bookmark.reference.localizedCaseInsensitiveContains(searchText) ||
                bookmark.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by category
        if let category = selectedCategory {
            results = results.filter { $0.category == category.rawValue }
        }
        
        return results
    }
    
    var groupedBookmarks: [(String, [Bookmark])] {
        switch groupBy {
        case .category:
            return groupByCategory(filteredBookmarks)
        case .date:
            return groupByDate(filteredBookmarks)
        case .book:
            return groupByBook(filteredBookmarks)
        case .pinned:
            return groupByPinned(filteredBookmarks)
        }
    }
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Bookmarks")
                .searchable(text: $searchText, prompt: "Search bookmarks...")
                .toolbar {
                    toolbarContent
                }
                .alert("Delete Bookmark", isPresented: $showingDeleteConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        if let bookmark = bookmarkToDelete {
                            deleteBookmark(bookmark)
                        }
                    }
                } message: {
                    Text("Are you sure you want to delete this bookmark?")
                }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        Group {
            if bookmarks.isEmpty {
                emptyStateView
            } else if filteredBookmarks.isEmpty {
                noResultsView
            } else {
                bookmarksList
            }
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("No Bookmarks Yet", systemImage: "bookmark")
        } description: {
            Text("Save your favorite verses and chapters for quick access")
        } actions: {
            Button("Add Bookmark") {
                showingAddBookmark = true
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var noResultsView: some View {
        ContentUnavailableView(
            "No Results",
            systemImage: "magnifyingglass",
            description: Text("Try a different search or filter")
        )
    }
    
    private var bookmarksList: some View {
        List {
            ForEach(groupedBookmarks, id: \.0) { section, sectionBookmarks in
                Section(header: Text(section)) {
                    ForEach(sectionBookmarks) { bookmark in
                        BookmarkRow(bookmark: bookmark)
                            .swipeActions(edge: .leading) {
                                Button {
                                    togglePin(bookmark)
                                } label: {
                                    Label(bookmark.isPinned ? "Unpin" : "Pin", 
                                          systemImage: bookmark.isPinned ? "pin.slash" : "pin")
                                }
                                .tint(.orange)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    bookmarkToDelete = bookmark
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button {
                                    togglePin(bookmark)
                                } label: {
                                    Label(bookmark.isPinned ? "Unpin" : "Pin", 
                                          systemImage: bookmark.isPinned ? "pin.slash.fill" : "pin.fill")
                                }
                                
                                Button {
                                    // Edit bookmark
                                } label: {
                                    Label("Edit", systemImage: "pencil")
                                }
                                
                                Button(role: .destructive) {
                                    bookmarkToDelete = bookmark
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showingAddBookmark = true
            } label: {
                Label("Add Bookmark", systemImage: "plus")
            }
        }
        
        ToolbarItem(placement: .navigationBarLeading) {
            Menu {
                // Category filter
                Menu {
                    Button {
                        selectedCategory = nil
                    } label: {
                        Label("All Categories", systemImage: "folder")
                    }
                    
                    Divider()
                    
                    ForEach(BookmarkCategory.allCases) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            Label(category.rawValue, systemImage: category.icon)
                                .foregroundStyle(category.color)
                        }
                    }
                } label: {
                    Label("Filter by Category", systemImage: "folder")
                }
                
                Divider()
                
                // Grouping
                Picker("Group By", selection: $groupBy) {
                    ForEach(GroupingOption.allCases, id: \.self) { option in
                        Label(option.rawValue, systemImage: option.icon)
                            .tag(option)
                    }
                }
            } label: {
                Label("Filter & Sort", systemImage: "line.3.horizontal.decrease.circle")
            }
        }
    }
    
    private func togglePin(_ bookmark: Bookmark) {
        withAnimation {
            bookmark.isPinned.toggle()
            try? modelContext.save()
        }
    }
    
    private func deleteBookmark(_ bookmark: Bookmark) {
        withAnimation {
            modelContext.delete(bookmark)
            try? modelContext.save()
        }
    }
    
    // MARK: - Grouping Functions
    
    private func groupByCategory(_ bookmarks: [Bookmark]) -> [(String, [Bookmark])] {
        let grouped = Dictionary(grouping: bookmarks) { $0.category }
        
        return grouped.sorted { first, second in
            // Sort by predefined category order
            let categories = BookmarkCategory.allCases.map { $0.rawValue }
            let firstIndex = categories.firstIndex(of: first.key) ?? Int.max
            let secondIndex = categories.firstIndex(of: second.key) ?? Int.max
            return firstIndex < secondIndex
        }
    }
    
    private func groupByDate(_ bookmarks: [Bookmark]) -> [(String, [Bookmark])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: bookmarks) { bookmark -> String in
            if calendar.isDateInToday(bookmark.createdAt) {
                return "Today"
            } else if calendar.isDateInYesterday(bookmark.createdAt) {
                return "Yesterday"
            } else if calendar.isDate(bookmark.createdAt, equalTo: Date(), toGranularity: .weekOfYear) {
                return "This Week"
            } else if calendar.isDate(bookmark.createdAt, equalTo: Date(), toGranularity: .month) {
                return "This Month"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: bookmark.createdAt)
            }
        }
        
        let order = ["Today", "Yesterday", "This Week", "This Month"]
        return grouped.sorted { first, second in
            if let firstIndex = order.firstIndex(of: first.key),
               let secondIndex = order.firstIndex(of: second.key) {
                return firstIndex < secondIndex
            } else if order.contains(first.key) {
                return true
            } else if order.contains(second.key) {
                return false
            } else {
                return first.key > second.key
            }
        }
    }
    
    private func groupByBook(_ bookmarks: [Bookmark]) -> [(String, [Bookmark])] {
        let grouped = Dictionary(grouping: bookmarks) { bookmark -> String in
            if let book = bookmark.chapter?.book ?? bookmark.verse?.chapter?.book {
                return book.name
            }
            return "Other"
        }
        
        return grouped.sorted { $0.key < $1.key }
    }
    
    private func groupByPinned(_ bookmarks: [Bookmark]) -> [(String, [Bookmark])] {
        let pinned = bookmarks.filter { $0.isPinned }
        let unpinned = bookmarks.filter { !$0.isPinned }
        
        var result: [(String, [Bookmark])] = []
        
        if !pinned.isEmpty {
            result.append(("Pinned", pinned))
        }
        if !unpinned.isEmpty {
            result.append(("All Bookmarks", unpinned))
        }
        
        return result
    }
}

// MARK: - Bookmark Row
struct BookmarkRow: View {
    @Bindable var bookmark: Bookmark
    
    var body: some View {
        NavigationLink(destination: destinationView) {
            HStack(alignment: .top, spacing: 12) {
                // Category color indicator
                RoundedRectangle(cornerRadius: 4)
                    .fill(bookmark.categoryColor)
                    .frame(width: 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    // Title and pin indicator
                    HStack {
                        Text(bookmark.displayTitle)
                            .font(.headline)
                            .lineLimit(2)
                        
                        if bookmark.isPinned {
                            Image(systemName: "pin.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                        
                        Spacer()
                    }
                    
                    // Reference
                    Text(bookmark.reference)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    // Notes preview
                    if !bookmark.notes.isEmpty {
                        Text(bookmark.notes)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .padding(.top, 2)
                    }
                    
                    // Category and date
                    HStack(spacing: 12) {
                        Label(bookmark.category, systemImage: categoryIcon)
                            .font(.caption2)
                            .foregroundStyle(bookmark.categoryColor)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                            Text(bookmark.createdAt.formatted(date: .abbreviated, time: .omitted))
                        }
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    }
                    .padding(.top, 4)
                }
            }
            .padding(.vertical, 4)
        }
    }
    
    @ViewBuilder
    private var destinationView: some View {
        if let chapter = bookmark.chapter {
            ChapterView(chapter: chapter, onChapterChange: { _ in })
        } else if let verse = bookmark.verse, let chapter = verse.chapter {
            ChapterView(chapter: chapter, onChapterChange: { _ in })
        } else {
            Text("Bookmark destination not found")
        }
    }
    
    private var categoryIcon: String {
        if let category = BookmarkCategory(rawValue: bookmark.category) {
            return category.icon
        }
        return "bookmark"
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Bookmark.self,
        Book.self,
        Chapter.self,
        Verse.self,
        configurations: config
    )
    
    let context = container.mainContext
    let book = Book(name: "Psalms", order: 19, testament: "OT")
    let chapter = Chapter(number: 23, book: book)
    let verse = Verse(number: 1, text: "The LORD is my shepherd; I shall not want.", chapter: chapter)
    
    let bookmark1 = Bookmark(
        title: "Shepherd Psalm",
        verse: verse,
        category: BookmarkCategory.comfort.rawValue,
        color: BookmarkCategory.comfort.color,
        notes: "A beautiful reminder of God's care",
        isPinned: true
    )
    
    let bookmark2 = Bookmark(
        title: "Study this chapter",
        chapter: chapter,
        category: BookmarkCategory.study.rawValue,
        color: BookmarkCategory.study.color
    )
    
    context.insert(book)
    context.insert(chapter)
    context.insert(verse)
    context.insert(bookmark1)
    context.insert(bookmark2)
    
    return BookmarksView()
        .modelContainer(container)
}