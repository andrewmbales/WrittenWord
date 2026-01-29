//
//  SidebarView.swift
//  WrittenWord
//
//  ENHANCED: Search opens in detail view, not sheet
//

import SwiftUI
import SwiftData

struct SidebarView: View {
    @Query(sort: \Book.order) private var books: [Book]
    @Binding var selectedChapter: Chapter?
    @Binding var showingSearch: Bool
    
    @State private var selectedBook: Book?
    @State private var showingSettings = false
    @State private var showingNotebook = false
    @State private var showingHighlights = false
    @State private var showingBookmarks = false
    @State private var showingStats = false
    
    var oldTestamentBooks: [Book] {
        books.filter { $0.testament == "OT" }
    }
    
    var newTestamentBooks: [Book] {
        books.filter { $0.testament == "NT" }
    }
    
    var body: some View {
        List {
            // Top navigation buttons
            Section {
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gear")
                        .foregroundStyle(.gray)
                }
                .buttonStyle(.plain)
                
                Button {
                    showingHighlights = true
                } label: {
                    Label("Highlights", systemImage: "highlighter")
                        .foregroundStyle(.yellow)
                }
                .buttonStyle(.plain)
                
                Button {
                    showingNotebook = true
                } label: {
                    Label("Notes", systemImage: "note.text")
                        .foregroundStyle(.orange)
                }
                .buttonStyle(.plain)
                
                Button {
                    selectedChapter = nil
                    showingSearch = true
                } label: {
                    Label("Search", systemImage: "magnifyingglass")
                        .foregroundStyle(.green)
                }
                .buttonStyle(.plain)
            }
            
            // Books of the Bible
            Section("BOOKS OF THE BIBLE") {
                if let selectedBook = selectedBook {
                    chapterGridView(for: selectedBook)
                } else {
                    twoColumnBookLayout
                }
            }
            
            // Study tools
            Section("My Study") {
                Button {
                    showingBookmarks = true
                } label: {
                    Label("Bookmarks", systemImage: "bookmark.fill")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                
                Button {
                    showingStats = true
                } label: {
                    Label("Statistics", systemImage: "chart.bar.fill")
                        .foregroundStyle(.purple)
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Written Word")
        // Sheets for views that need them
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
            }
        }
        .sheet(isPresented: $showingNotebook) {
            NavigationStack {
                NotebookView_Optimized()
            }
        }
        .sheet(isPresented: $showingHighlights) {
            NavigationStack {
                HighlightsView()
            }
        }
        .sheet(isPresented: $showingBookmarks) {
            NavigationStack {
                BookmarksView()
            }
        }
        .sheet(isPresented: $showingStats) {
            NavigationStack {
                HighlightStatsView()
            }
        }
    }
    
    // MARK: - Two Column Book Layout
    private var twoColumnBookLayout: some View {
        HStack(alignment: .top, spacing: 20) {
            // Old Testament Column
            VStack(alignment: .leading, spacing: 8) {
                ForEach(oldTestamentBooks) { book in
                    Button {
                        selectedBook = book
                    } label: {
                        Text(book.name)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // New Testament Column
            VStack(alignment: .leading, spacing: 8) {
                ForEach(newTestamentBooks) { book in
                    Button {
                        selectedBook = book
                    } label: {
                        Text(book.name)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Chapter Grid View
    private func chapterGridView(for book: Book) -> some View {
        let columns = [
            GridItem(.adaptive(minimum: 40, maximum: 50), spacing: 8)
        ]
        
        return VStack(alignment: .leading, spacing: 12) {
            // Back button
            HStack {
                Button {
                    selectedBook = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.caption)
                        Text("Books")
                            .font(.subheadline)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            
            Text(book.name)
                .font(.title2.bold())
            
            // Chapter numbers grid
            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                ForEach(book.chapters.sorted(by: { $0.number < $1.number })) { chapter in
                    Button {
                        selectedChapter = chapter
                    } label: {
                        Text("\(chapter.number)")
                            .font(.subheadline)
                            .fontWeight(selectedChapter?.id == chapter.id ? .bold : .regular)
                            .foregroundColor(selectedChapter?.id == chapter.id ? .white : .primary)
                            .frame(width: 40, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedChapter?.id == chapter.id ? Color.accentColor : Color.secondary.opacity(0.1))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 8)
    }
}
