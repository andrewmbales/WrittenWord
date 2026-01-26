//
//  HighlightsView.swift
//  WrittenWord
//
//  Phase 1: Dedicated view for all highlights
//
import SwiftUI
import SwiftData

struct HighlightsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Highlight.createdAt, order: .reverse) private var highlights: [Highlight]
    
    @State private var searchText = ""
    @State private var selectedColor: HighlightColor?
    @State private var groupBy: GroupingOption = .color
    @State private var showingDeleteConfirmation = false
    @State private var highlightToDelete: Highlight?
    
    enum GroupingOption: String, CaseIterable {
        case color = "Color"
        case date = "Date"
        case book = "Book"
        
        var icon: String {
            switch self {
            case .color: return "paintpalette"
            case .date: return "calendar"
            case .book: return "book.closed"
            }
        }
    }
    
    var filteredHighlights: [Highlight] {
        var result = highlights
        
        // Filter by search
        if !searchText.isEmpty {
            result = result.filter { highlight in
                highlight.text.localizedCaseInsensitiveContains(searchText) ||
                (highlight.verse?.reference ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Filter by color
        if let selectedColor = selectedColor {
            result = result.filter { highlight in
                highlight.highlightColor.toHex() == selectedColor.color.toHex()
            }
        }
        
        return result
    }
    
    var groupedHighlights: [(String, [Highlight])] {
        switch groupBy {
        case .color:
            return groupByColor(filteredHighlights)
        case .date:
            return groupByDate(filteredHighlights)
        case .book:
            return groupByBook(filteredHighlights)
        }
    }
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Highlights")
                .searchable(text: $searchText, prompt: "Search highlights...")
                .toolbar {
                    toolbarContent
                }
                .alert("Delete Highlight", isPresented: $showingDeleteConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        if let highlight = highlightToDelete {
                            deleteHighlight(highlight)
                        }
                    }
                } message: {
                    Text("Are you sure you want to delete this highlight?")
                }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        Group {
            if highlights.isEmpty {
                emptyStateView
            } else if filteredHighlights.isEmpty {
                noResultsView
            } else {
                highlightsList
            }
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Highlights Yet",
            systemImage: "highlighter",
            description: Text("Select text in any chapter to create your first highlight")
        )
    }
    
    private var noResultsView: some View {
        ContentUnavailableView(
            "No Results",
            systemImage: "magnifyingglass",
            description: Text("Try a different search or filter")
        )
    }
    
    private var highlightsList: some View {
        List {
            ForEach(groupedHighlights, id: \.0) { section, sectionHighlights in
                Section(header: Text(section)) {
                    ForEach(sectionHighlights) { highlight in
                        HighlightRow(highlight: highlight)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    highlightToDelete = highlight
                                    showingDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button {
                                    UIPasteboard.general.string = highlight.text
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                                
                                Button(role: .destructive) {
                                    highlightToDelete = highlight
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
            Menu {
                // Color filter
                Menu {
                    Button {
                        selectedColor = nil
                    } label: {
                        Label("All Colors", systemImage: "circle.grid.cross")
                    }
                    
                    Divider()
                    
                    ForEach(HighlightColor.allCases, id: \.self) { color in
                        Button {
                            selectedColor = color
                        } label: {
                            Label(color.rawValue, systemImage: "circle.fill")
                                .foregroundColor(color.color)
                        }
                    }
                } label: {
                    Label("Filter by Color", systemImage: "paintpalette")
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
    
    private func deleteHighlight(_ highlight: Highlight) {
        withAnimation {
            modelContext.delete(highlight)
            try? modelContext.save()
        }
    }
    
    // MARK: - Grouping Functions
    
    private func groupByColor(_ highlights: [Highlight]) -> [(String, [Highlight])] {
        let grouped = Dictionary(grouping: highlights) { highlight -> String in
            // Match highlight color to HighlightColor enum
            if let matchingColor = HighlightColor.allCases.first(where: { 
                $0.color.toHex() == highlight.highlightColor.toHex() 
            }) {
                return matchingColor.rawValue
            }
            return "Other"
        }
        
        let order = HighlightColor.allCases.map { $0.rawValue } + ["Other"]
        return grouped.sorted { first, second in
            let firstIndex = order.firstIndex(of: first.key) ?? Int.max
            let secondIndex = order.firstIndex(of: second.key) ?? Int.max
            return firstIndex < secondIndex
        }
    }
    
    private func groupByDate(_ highlights: [Highlight]) -> [(String, [Highlight])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: highlights) { highlight -> String in
            if calendar.isDateInToday(highlight.createdAt) {
                return "Today"
            } else if calendar.isDateInYesterday(highlight.createdAt) {
                return "Yesterday"
            } else if calendar.isDate(highlight.createdAt, equalTo: Date(), toGranularity: .weekOfYear) {
                return "This Week"
            } else if calendar.isDate(highlight.createdAt, equalTo: Date(), toGranularity: .month) {
                return "This Month"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: highlight.createdAt)
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
    
    private func groupByBook(_ highlights: [Highlight]) -> [(String, [Highlight])] {
        let grouped = Dictionary(grouping: highlights) { highlight -> String in
            if let book = highlight.verse?.chapter?.book {
                return book.name
            }
            return "Other"
        }
        
        return grouped.sorted { $0.key < $1.key }
    }
}

struct HighlightRow: View {
    let highlight: Highlight
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Color indicator
            RoundedRectangle(cornerRadius: 4)
                .fill(highlight.highlightColor)
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 6) {
                // Highlighted text
                Text(highlight.text)
                    .font(.body)
                    .padding(8)
                    .background(highlight.highlightColor.opacity(0.3))
                    .cornerRadius(6)
                
                // Reference
                Text(highlight.verse?.reference ?? "Unknown")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // Date
                HStack {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(highlight.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                }
                .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Highlight.self,
        Verse.self,
        Chapter.self,
        Book.self,
        configurations: config
    )
    
    let context = container.mainContext
    let book = Book(name: "Genesis", order: 1, testament: "OT")
    let chapter = Chapter(number: 1, book: book)
    let verse = Verse(number: 1, text: "In the beginning God created the heaven and the earth.", chapter: chapter)
    
    let highlight1 = Highlight(verseId: verse.id, startIndex: 17, endIndex: 20, color: .yellow, text: "God", verse: verse)
    let highlight2 = Highlight(verseId: verse.id, startIndex: 29, endIndex: 35, color: .green, text: "heaven", verse: verse)
    
    context.insert(book)
    context.insert(chapter)
    context.insert(verse)
    context.insert(highlight1)
    context.insert(highlight2)
    
    return HighlightsView()
        .modelContainer(container)
}
