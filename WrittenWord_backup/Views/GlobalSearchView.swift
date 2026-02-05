//
//  GlobalSearchView.swift
//  WrittenWord
//
//  FIXED: Uses chapter binding instead of NavigationLink
//

import SwiftUI
import SwiftData

struct GlobalSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var allVerses: [Verse]
    
    @State private var searchText = ""
    @State private var searchResults: [SearchResult] = []
    @State private var isSearching = false
    
    var filteredResults: [SearchResult] {
        searchResults
    }
    
    var body: some View {
        VStack(spacing: 0) {
            mainContent
        }
        .navigationTitle("Search Bible")
        .searchable(text: $searchText, prompt: "Search...")
        .onChange(of: searchText) { _, newValue in
            performSearch(query: newValue)
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
    
    private var resultsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                Text("\(filteredResults.count) results")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top)
                
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
            return
        }
        
        isSearching = true
        
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
            
            HighlightedSearchText(
                text: result.contextText,
                searchQuery: searchQuery
            )
            .font(.body)
            .lineLimit(3)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(8)
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
