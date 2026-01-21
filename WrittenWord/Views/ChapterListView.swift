//
//  ChapterListView.swift
//  WrittenWord
//
//  Created by Andrew Bales on 1/21/26.
//
import SwiftUI
import SwiftData

struct ChapterListView: View {
    let book: Book
    @State private var selectedChapter: Chapter?
    
    var sortedChapters: [Chapter] {
        book.chapters.sorted { $0.number < $1.number }
    }
    
    private var columns: [GridItem] {
        [GridItem(.adaptive(minimum: 60, maximum: 80), spacing: 12)]
    }
    
    var body: some View {
        Group {
            if sortedChapters.isEmpty {
                ContentUnavailableView(
                    "No Chapters",
                    systemImage: "book",
                    description: Text("This book doesn't have any chapters yet")
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(sortedChapters) { chapter in
                            NavigationLink(value: chapter) {
                                Text("\(chapter.number)")
                                    .font(.headline)
                                    .frame(width: 50, height: 50)
                                    .background(selectedChapter?.id == chapter.id ? Color.blue : Color.blue.opacity(0.1))
                                    .foregroundColor(selectedChapter?.id == chapter.id ? .white : .blue)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(book.name)
        .navigationDestination(for: Chapter.self) { chapter in
            ChapterView(chapter: chapter)
        }
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
    let chapter = Chapter(number: 1, book: book)
    book.chapters = [chapter]
    
    return NavigationStack {
        ChapterListView(book: book)
    }
    .modelContainer(container)
}