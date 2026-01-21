//
//  ChapterView.swift
//  WrittenWord
//
//  Created by Andrew Bales on 1/21/26.
//
import SwiftUI
import SwiftData

struct ChapterView: View {
    let chapter: Chapter
    @State private var showingDrawing = false
    @State private var selectedVerse: Verse?
    
    var sortedVerses: [Verse] {
        chapter.verses.sorted { $0.number < $1.number }
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    ForEach(sortedVerses) { verse in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(verse.number)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 30, alignment: .trailing)
                            
                            Text(verse.text)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .id(verse.id)
                        .contextMenu {
                            Button {
                                selectedVerse = verse
                                showingDrawing = true
                            } label: {
                                Label("Add Note", systemImage: "note.text")
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("\(chapter.book?.name ?? "") \(chapter.number)")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    selectedVerse = nil
                    showingDrawing = true
                } label: {
                    Image(systemName: "note.text.badge.plus")
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    NotificationCenter.default.post(name: .showNotesColumn, object: nil)
                } label: {
                    Image(systemName: "sidebar.right")
                }
            }
        }
        .sheet(isPresented: $showingDrawing) {
            NavigationStack {
                if let verse = selectedVerse {
                    DrawingView(verse: verse)
                } else {
                    DrawingView(chapter: chapter)
                }
            }
        }
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Book.self,
            Chapter.self,
            Verse.self,
            Note.self,
            configurations: config
        )
        
        // Create sample data
        let book = Book(name: "Genesis", order: 1, testament: "OT")
        let chapter = Chapter(number: 1)
        chapter.book = book
        book.chapters = [chapter]
        
        let verse = Verse(number: 1, text: "In the beginning, God created the heavens and the earth.", chapter: chapter)
        chapter.verses = [verse]
        
        return NavigationStack {
            ChapterView(chapter: chapter)
        }
        .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}