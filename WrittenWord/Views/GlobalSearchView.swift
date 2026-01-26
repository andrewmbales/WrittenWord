//
//  GlobalSearchView.swift
//  WrittenWord
//
//  Phase 2: Global Bible Search
//
import SwiftUI
import SwiftData
import Charts

struct GlobalSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allBooks: [Book]
    @Query private var allVerses: [Verse]
    
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false
    @State private var selectedScope: SearchScope = .all
    @State private var selectedSort: SearchSortOption = .relevance
    @State private var showDistributionChart = false
    @State private var selectedBook: Book?
    
    var filteredResults: [SearchResult] {
        var results = searchResults
        
        // Apply scope filter
        switch selectedScope {
        case .all:
            break
        case .oldTestament:
            results = results.filter { $0.book.testament == "OT" }
        case .newTestament:
            results = results.filter { $0.book.testament == "NT" }
        case .currentBook:
            if let book = selectedBook {
                results = results.filter { $0.book.id == book.id }
            }
        }
        
        // Apply sorting
        switch selectedSort {
        case .relevance:
            // Already sorted by relevance during search
            break
        case .bookOrder:
            results.sort { $0.book.order < $1.book.order }
        case .verseNumber:
            results.sort { $0.verse.number < $1.verse.number }
        }
        
        return results
    }
    
    var bookDistribution: [BookDistribution] {
        let bookCounts = Dictionary(grouping: filteredResults) { $0.book }
            .mapValues { $0.count }
        
        let total = filteredResults.count
        
        return bookCounts.map { book, count in
            BookDistribution(
                book: book,
                count: count,
                percentage: total > 0 ? Double(count) / Double(total) * 100 : 0
            )
        }
        .sorted { $0.count > $1.count }
        .prefix(10)
        .map { $0 }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search stats and controls
                if !searchResults.isEmpty {
                    searchStatsBar
                    Divider()
                }
                
                // Distribution chart (collapsible)
                if showDistributionChart && !filteredResults.isEmpty {
                    distributionChartSection
                    Divider()
                }
                
                // Results list
                mainContent
            }
            .navigationTitle("Search Bible")
            .searchable(text: $searchText, prompt: "Search all of Scripture...")
            .onChange(of: searchText) { oldValue, newValue in
                performSearch(query: newValue)
            }
            .toolbar {
                toolbarContent
            }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        if searchText.isEmpty {
            emptyStateView
        } else if isSearching {
            loadingView
        } else if filteredResults.isEmpty {
            noResultsView
        } else {
            resultsList
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView {
            Label("Search the Bible", systemImage: "magnifyingglass")
        } description: {
            VStack(spacing: 12) {
                Text("Search across all books and chapters")
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Examples:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Text("• \"faith\" - Find all verses with this word")
                    Text("• \"love one another\" - Search phrases")
                    Text("• \"John 3:16\" - Find specific verses")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Searching Scripture...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxHeight: .infinity)
    }
    
    private var noResultsView: some View {
        ContentUnavailableView {
            Label("No Results", systemImage: "text.magnifyingglass")
        } description: {
            Text("No verses found for \"\(searchText)\"")
        } actions: {
            Button("Clear Search") {
                searchText = ""
            }
        }
    }
    
    private var searchStatsBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(filteredResults.count) results")
                    .font(.headline)
                Text("in \(Set(filteredResults.map { $0.book.name }).count) books")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                withAnimation {
                    showDistributionChart.toggle()
                }
            } label: {
                Label(
                    showDistributionChart ? "Hide Chart" : "Show Chart",
                    systemImage: "chart.bar.fill"
                )
                .font(.caption)
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
    }
    
    private var distributionChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Distribution by Book")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if #available(iOS 16.0, *) {
                Chart(bookDistribution.prefix(10)) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Book", item.book.abbreviation)
                    )
                    .foregroundStyle(Color.accentColor)
                    .annotation(position: .trailing) {
                        Text("\(item.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 200)
                .chartXAxis(.hidden)
            } else {
                // Fallback for iOS 15
                VStack(spacing: 8) {
                    ForEach(bookDistribution.prefix(5)) { item in
                        HStack {
                            Text(item.book.abbreviation)
                                .font(.caption)
                                .frame(width: 50, alignment: .leading)
                            
                            GeometryReader { geometry in
                                HStack(spacing: 0) {
                                    Rectangle()
                                        .fill(Color.accentColor)
                                        .frame(width: geometry.size.width * (item.percentage / 100))
                                    
                                    Spacer(minLength: 0)
                                }
                            }
                            .frame(height: 20)
                            
                            Text("\(item.count)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.3))
    }
    
    private var resultsList: some View {
        List {
            ForEach(filteredResults) { result in
                NavigationLink(destination: ChapterView(
                    chapter: result.chapter,
                    onChapterChange: { _ in }
                )) {
                    SearchResultRow(result: result, searchQuery: searchText)
                }
            }
        }
        .listStyle(.plain)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                // Scope picker
                Picker("Search In", selection: $selectedScope) {
                    ForEach(SearchScope.allCases) { scope in
                        Label(scope.rawValue, systemImage: scope.icon)
                            .tag(scope)
                    }
                }
                
                Divider()
                
                // Sort picker
                Picker("Sort By", selection: $selectedSort) {
                    ForEach(SearchSortOption.allCases) { sort in
                        Label(sort.rawValue, systemImage: sort.icon)
                            .tag(sort)
                    }
                }
            } label: {
                Label("Options", systemImage: "slider.horizontal.3")
            }
        }
    }
    
    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            return
        }
        
        isSearching = true
        
        // Perform search in background
        Task {
            let results = await searchVerses(query: query)
            
            await MainActor.run {
                searchResults = results
                isSearching = false
            }
        }
    }
    
    private func searchVerses(query: String) async -> [SearchResult] {
        let lowercaseQuery = query.lowercased()
        var results: [SearchResult] = []
        
        // Search through all verses
        for verse in allVerses {
            if verse.text.lowercased().contains(lowercaseQuery) {
                if let chapter = verse.chapter,
                   let book = chapter.book {
                    results.append(SearchResult(
                        verse: verse,
                        matchedText: query,
                        book: book,
                        chapter: chapter
                    ))
                }
            }
        }
        
        return results
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let result: SearchResult
    let searchQuery: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Reference
            HStack {
                Text(result.reference)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                Text(result.book.testament)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(result.book.testament == "OT" ? Color.purple.opacity(0.2) : Color.blue.opacity(0.2))
                    .foregroundColor(result.book.testament == "OT" ? .purple : .blue)
                    .cornerRadius(4)
            }
            
            // Verse text with highlighted search term
            HighlightedSearchText(
                text: result.contextText,
                searchQuery: searchQuery
            )
            .font(.body)
            .lineLimit(3)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Highlighted Search Text
struct HighlightedSearchText: View {
    let text: String
    let searchQuery: String
    
    var attributedText: AttributedString {
        var attributed = AttributedString(text)
        
        // Find and highlight all occurrences of search query
        let lowercaseText = text.lowercased()
        let lowercaseQuery = searchQuery.lowercased()
        
        var searchStartIndex = lowercaseText.startIndex
        
        while let range = lowercaseText[searchStartIndex...].range(of: lowercaseQuery) {
            // Convert String range to AttributedString range
            if let attrRange = Range<AttributedString.Index>(range, in: attributed) {
                attributed[attrRange].backgroundColor = Color.yellow.opacity(0.4)
                attributed[attrRange].font = .body.bold()
            }
            
            searchStartIndex = range.upperBound
            if searchStartIndex >= lowercaseText.endIndex {
                break
            }
        }
        
        return attributed
    }
    
    var body: some View {
        Text(attributedText)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Book.self,
        Chapter.self,
        Verse.self,
        configurations: config
    )
    
    let context = container.mainContext
    let book = Book(name: "Genesis", order: 1, testament: "OT")
    let chapter = Chapter(number: 1, book: book)
    let verse1 = Verse(number: 1, text: "In the beginning God created the heaven and the earth.", chapter: chapter)
    let verse2 = Verse(number: 2, text: "And the earth was without form, and void; and darkness was upon the face of the deep.", chapter: chapter)
    
    context.insert(book)
    context.insert(chapter)
    context.insert(verse1)
    context.insert(verse2)
    
    return GlobalSearchView()
        .modelContainer(container)
}