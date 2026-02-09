//
//  GlobalSearchView.swift
//  WrittenWord
//
//  REDESIGNED: Large centered search bar instead of .searchable
//

import SwiftUI
import SwiftData

struct GlobalSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allVerses: [Verse]

    @AppStorage("colorTheme") private var colorTheme: ColorTheme = .system

    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false
    @State private var hasSearched = false
    @State private var selectedSection: BibleSection?
    @FocusState private var isSearchFieldFocused: Bool

    var filteredResults: [SearchResult] {
        guard let section = selectedSection else { return searchResults }
        return searchResults.filter { section.orderRange.contains($0.book.order) }
    }

    var body: some View {
        VStack(spacing: 0) {
            if hasSearched && !isSearching {
                // Post-search: compact search bar at top + results
                compactSearchBar
                Divider()

                if filteredResults.isEmpty {
                    noResultsView
                } else {
                    resultsList
                }
            } else if isSearching {
                compactSearchBar
                Divider()
                loadingView
            } else {
                // Landing: large centered search bar
                landingView
            }
        }
        .background(colorTheme.backgroundColor)
        .navigationTitle("Search Bible")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            // Auto-focus the search field on appear
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isSearchFieldFocused = true
            }
        }
    }

    // MARK: - Landing View (large centered search bar)

    private var landingView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(.secondary.opacity(0.5))

            Text("Search the Bible")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(colorTheme.textColor)

            // Large search field
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.title3)

                TextField("Search verses...", text: $searchText)
                    .font(.title3)
                    .foregroundStyle(colorTheme.textColor)
                    .focused($isSearchFieldFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        performSearch(query: searchText)
                    }

                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(colorTheme.textColor.opacity(0.08))
            .cornerRadius(14)
            .padding(.horizontal, 60)

            // Hints
            VStack(alignment: .leading, spacing: 8) {
                Text("Examples:")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)

                Text("\"faith\" \u{2022} \"love one another\" \u{2022} \"beginning\"")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)

            Spacer()
            Spacer()
        }
    }

    // MARK: - Compact Search Bar (after first search)

    private var compactSearchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("Search verses...", text: $searchText)
                .foregroundStyle(colorTheme.textColor)
                .focused($isSearchFieldFocused)
                .submitLabel(.search)
                .onSubmit {
                    performSearch(query: searchText)
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchResults = []
                    hasSearched = false
                    selectedSection = nil
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(colorTheme.textColor.opacity(0.06))
    }

    // MARK: - Views

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
                searchResults = []
                hasSearched = false
                selectedSection = nil
            }
        }
    }

    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Frequency chart
                SearchFrequencyChart(
                    results: searchResults,
                    selectedSection: $selectedSection
                )
                .padding(.horizontal)
                .padding(.top)

                // Results header
                HStack {
                    Text("\(filteredResults.count) results")
                        .font(.headline)
                    Spacer()
                    if selectedSection != nil {
                        Button {
                            withAnimation { selectedSection = nil }
                        } label: {
                            Label("Clear Filter", systemImage: "xmark.circle.fill")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                ForEach(filteredResults) { result in
                    SearchResultRow(result: result, searchQuery: searchText)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom)
        }
    }

    private func performSearch(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            isSearching = false
            hasSearched = false
            return
        }

        isSearching = true
        selectedSection = nil

        Task {
            let results = await searchVerses(query: query)

            await MainActor.run {
                searchResults = results
                isSearching = false
                hasSearched = true
            }
        }
    }

    private func searchVerses(query: String) async -> [SearchResult] {
        let lowercaseQuery = query.lowercased()
        var results: [SearchResult] = []

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

        // Sort by book order, then chapter, then verse
        results.sort { a, b in
            if a.book.order != b.book.order { return a.book.order < b.book.order }
            if a.chapter.number != b.chapter.number { return a.chapter.number < b.chapter.number }
            return a.verse.number < b.verse.number
        }

        return results
    }
}

// MARK: - Search Result Row
struct SearchResultRow: View {
    let result: SearchResult
    let searchQuery: String

    @AppStorage("colorTheme") private var colorTheme: ColorTheme = .system

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(result.reference)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(colorTheme.textColor)

                Spacer()

                Text(result.book.testament)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(result.book.testament == "OT" ? Color.purple.opacity(0.2) : Color.blue.opacity(0.2))
                    .foregroundColor(result.book.testament == "OT" ? .purple : .blue)
                    .cornerRadius(4)
            }

            HighlightedSearchText(
                text: result.contextText,
                searchQuery: searchQuery
            )
            .font(.body)
            .foregroundStyle(colorTheme.textColor)
            .lineLimit(3)
        }
        .padding()
        .background(colorTheme.textColor.opacity(0.06))
        .cornerRadius(8)
    }
}

// MARK: - Search Frequency Chart
struct SearchFrequencyChart: View {
    let results: [SearchResult]
    @Binding var selectedSection: BibleSection?

    @AppStorage("colorTheme") private var colorTheme: ColorTheme = .system

    private var sectionCounts: [(section: BibleSection, count: Int)] {
        BibleSection.allCases.compactMap { section in
            let count = results.filter { section.orderRange.contains($0.book.order) }.count
            return count > 0 ? (section, count) : nil
        }
    }

    private var maxCount: Int {
        sectionCounts.map(\.count).max() ?? 1
    }

    /// Single bar color derived from the app's color theme
    private var barColor: Color {
        colorTheme.textColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            Text("\(results.count) verses found. Tap chart to filter.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Bars
            VStack(spacing: 6) {
                ForEach(sectionCounts, id: \.section) { item in
                    let isActive = selectedSection == nil || selectedSection == item.section
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedSection == item.section {
                                selectedSection = nil
                            } else {
                                selectedSection = item.section
                            }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Text(item.section.rawValue)
                                .font(.caption)
                                .foregroundStyle(isActive ? .primary : .tertiary)
                                .frame(width: 120, alignment: .trailing)
                                .lineLimit(1)

                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(barColor.opacity(isActive ? 0.7 : 0.2))
                                    .frame(
                                        width: max(4, geo.size.width * CGFloat(item.count) / CGFloat(maxCount))
                                    )
                            }
                            .frame(height: 20)

                            Text("\(item.count)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(isActive ? .primary : .tertiary)
                                .frame(width: 40, alignment: .leading)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding()
        .background(colorTheme.textColor.opacity(0.06))
        .cornerRadius(12)
    }
}

// MARK: - Highlighted Search Text
struct HighlightedSearchText: View {
    let text: String
    let searchQuery: String

    var attributedText: AttributedString {
        var attributed = AttributedString(text)

        let lowercaseText = text.lowercased()
        let lowercaseQuery = searchQuery.lowercased()

        var searchStartIndex = lowercaseText.startIndex

        while let range = lowercaseText[searchStartIndex...].range(of: lowercaseQuery) {
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
