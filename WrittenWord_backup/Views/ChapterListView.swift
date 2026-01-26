//
//  ChapterListView.swift
//  WrittenWord
//
//  Enhanced with improved visual design
//
import SwiftUI
import SwiftData

struct ChapterListView: View {
    let book: Book
    @Binding var selectedChapter: Chapter?
    
    var sortedChapters: [Chapter] {
        book.chapters.sorted { $0.number < $1.number }
    }
    
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 70, maximum: 90), spacing: 16)]
    }
    
    var body: some View {
        mainContent
            .navigationTitle(book.name)
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Chapter.self) { chapter in
                ChapterView(chapter: chapter, onChapterChange: { _ in })
            }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        Group {
            if sortedChapters.isEmpty {
                emptyStateView
            } else {
                chaptersScrollView
            }
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Chapters",
            systemImage: "book.closed",
            description: Text("This book doesn't have any chapters yet")
        )
    }
    
    private var chaptersScrollView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                bookHeaderView
                Divider()
                    .padding(.horizontal)
                chapterGrid
                    .padding(.horizontal)
            }
            .padding(.bottom)
        }
    }
    
    private var bookHeaderView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(book.name)
                .font(.largeTitle.bold())
            Text("\(sortedChapters.count) chapter\(sortedChapters.count == 1 ? "" : "s")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var chapterGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(sortedChapters) { chapter in
                NavigationLink(value: chapter) {
                    ChapterButton(
                        number: chapter.number,
                        isSelected: selectedChapter?.id == chapter.id
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ChapterButton: View {
    let number: Int
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1))
                .shadow(color: isSelected ? Color.accentColor.opacity(0.3) : .clear, radius: 8, y: 4)
            
            Text("\(number)")
                .font(.title2.bold())
                .foregroundColor(isSelected ? .white : .accentColor)
        }
        .frame(width: 70, height: 70)
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Book.self,
        Chapter.self,
        configurations: config
    )
    
    let book = Book(name: "Genesis", order: 1, testament: "OT")
    for i in 1...50 {
        let chapter = Chapter(number: i, book: book)
        book.chapters.append(chapter)
    }
    
    return NavigationStack {
        ChapterListView(book: book, selectedChapter: .constant(nil))
    }
    .modelContainer(container)
}
