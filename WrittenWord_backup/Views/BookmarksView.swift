//
//  BookmarksView.swift
//  WrittenWord
//
//  UPDATED: Direct navigation to chapters using NavigationLink(value:)
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
        
        if !searchText.isEmpty {
            results = results.filter { bookmark in
                bookmark.displayTitle.localizedCaseInsensitiveContains(searchText) ||
                bookmark.reference.localizedCaseInsensitiveContains(searchText) ||
                bookmark.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        
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
                        // CRITICAL: Direct navigation to chapter
                        if let chapter = bookmark.chapter ?? bookmark.verse?.chapter {
                            NavigationLink(value: chapter) {
                                BookmarkRow(bookmark: bookmark)
                            }
                        } else {
                            BookmarkRow(bookmark: bookmark)
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            // Toggle pin
                            for bookmark in sectionBookmarks {
                                bookmark.isPinned.toggle()
                            }
                            try? modelContext.save()
                        } label: {
                            Label("Pin", systemImage: "pin")
                        }
                        .tint(.orange)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            // Delete handled per item
                        } label: {
                            Label("Delete", systemImage: "trash")
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
    
    private func deleteBookmark(_ bookmark: Bookmark) {
        withAnimation {
            modelContext.delete(bookmark)
            try? modelContext.save()
        }
    }
    
    // MARK: - Grouping Functions (same as before)
    private func groupByCategory(_ bookmarks: [Bookmark]) -> [(String, [Bookmark])] {
        let grouped = Dictionary(grouping: bookmarks) { $0.category }
        let categories = BookmarkCategory.allCases.map { $0.rawValue }
        return grouped.sorted { first, second in
            let firstIndex = categories.firstIndex(of: first.key) ?? Int.max
            let secondIndex = categories.firstIndex(of: second.key) ?? Int.max
            return firstIndex < secondIndex
        }
    }
    
    private func groupByDate(_ bookmarks: [Bookmark]) -> [(String, [Bookmark])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: bookmarks) { bookmark -> String in
            if calendar.isDateInToday(bookmark.createdAt) { return "Today" }
            if calendar.isDateInYesterday(bookmark.createdAt) { return "Yesterday" }
            if calendar.isDate(bookmark.createdAt, equalTo: Date(), toGranularity: .weekOfYear) { return "This Week" }
            if calendar.isDate(bookmark.createdAt, equalTo: Date(), toGranularity: .month) { return "This Month" }
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: bookmark.createdAt)
        }
        
        let order = ["Today", "Yesterday", "This Week", "This Month"]
        return grouped.sorted { first, second in
            if let firstIndex = order.firstIndex(of: first.key),
               let secondIndex = order.firstIndex(of: second.key) {
                return firstIndex < secondIndex
            } else if order.contains(first.key) { return true }
            else if order.contains(second.key) { return false }
            else { return first.key > second.key }
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
        if !pinned.isEmpty { result.append(("Pinned", pinned)) }
        if !unpinned.isEmpty { result.append(("All Bookmarks", unpinned)) }
        return result
    }
}

struct BookmarkRow: View {
    @Bindable var bookmark: Bookmark
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(bookmark.categoryColor)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(bookmark.displayTitle)
                        .font(.headline)
                        .lineLimit(2)
                    
                    if bookmark.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(.gray)
                    }
                    
                    Spacer()
                }
                
                Text(bookmark.reference)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if !bookmark.notes.isEmpty {
                    Text(bookmark.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .padding(.top, 2)
                }
                
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
    
    private var categoryIcon: String {
        if let category = BookmarkCategory(rawValue: bookmark.category) {
            return category.icon
        }
        return "bookmark"
    }
}
