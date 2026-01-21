//
//  MainView.swift
//  WrittenWord
//
//  Created by Andrew Bales on 1/21/26.
//
import SwiftUI
import SwiftData

struct MainView: View {
    @State private var selectedBook: Book?
    @State private var selectedChapter: Chapter?
    @State private var selectedView: SidebarViewType? = .bible
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showingNoteColumn = false
    @AppStorage("notePosition") private var notePosition: NotePosition = .right
    
    var body: some View {
        Group {
            if notePosition == .right {
                notesOnRightLayout
            } else {
                notesOnLeftLayout
            }
        }
        .onChange(of: selectedChapter) { oldValue, newValue in
            // When a chapter is selected, minimize the first two columns
            if newValue != nil {
                withAnimation(.easeInOut(duration: 0.3)) {
                    columnVisibility = notePosition == .right ? .detailOnly : .all
                }
            } else if selectedBook != nil {
                // If no chapter but book is selected, show content and detail
                withAnimation(.easeInOut(duration: 0.3)) {
                    columnVisibility = .all
                }
            }
        }
        .onChange(of: selectedBook) { oldValue, newValue in
            // Reset chapter when book changes
            selectedChapter = nil
            showingNoteColumn = false
            // If no book selected, show all columns
            if newValue == nil {
                withAnimation(.easeInOut(duration: 0.3)) {
                    columnVisibility = .all
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showNotesColumn)) { notification in
            showingNoteColumn = true
        }
    }
    
    // Notes on the right layout
    private var notesOnRightLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selectedBook: $selectedBook)
        } content: {
            if let selectedBook {
                ChapterListView(book: selectedBook)
            } else {
                ContentUnavailableView("Select a Book", systemImage: "book")
            }
        } detail: {
            HStack(spacing: 0) {
                // Main content
                if let selectedChapter {
                    ChapterView(chapter: selectedChapter)
                        .frame(maxWidth: showingNoteColumn ? .infinity : nil)
                } else {
                    ContentUnavailableView("Select a Chapter", systemImage: "book.pages")
                        .frame(maxWidth: showingNoteColumn ? .infinity : nil)
                }
                
                // Notes column
                if showingNoteColumn {
                    Divider()
                    NotesColumn(
                        chapter: selectedChapter,
                        onClose: { showingNoteColumn = false }
                    )
                    .frame(width: 300)
                }
            }
        }
    }
    
    // Notes on the left layout
    private var notesOnLeftLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selectedBook: $selectedBook)
        } content: {
            if showingNoteColumn {
                NotesColumn(
                    chapter: selectedChapter,
                    onClose: { showingNoteColumn = false }
                )
            } else if let selectedBook {
                ChapterListView(book: selectedBook)
            } else {
                ContentUnavailableView("Select a Book", systemImage: "book")
            }
        } detail: {
            if let selectedChapter {
                ChapterView(chapter: selectedChapter)
            } else {
                ContentUnavailableView("Select a Chapter", systemImage: "book.pages")
            }
        }
    }
}

enum NotePosition: String, CaseIterable {
    case left = "left"
    case right = "right"
    
    var displayName: String {
        switch self {
        case .left: return "Left"
        case .right: return "Right"
        }
    }
}

extension Notification.Name {
    static let showNotesColumn = Notification.Name("showNotesColumn")
}

struct NotesColumn: View {
    let chapter: Chapter?
    let onClose: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]
    @State private var showingNewNote = false
    
    var chapterNotes: [Note] {
        guard let chapter = chapter else { return [] }
        return notes.filter { $0.chapter?.id == chapter.id }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Notes")
                    .font(.headline)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(.separator)),
                alignment: .bottom
            )
            
            // Notes list
            if chapterNotes.isEmpty {
                ContentUnavailableView(
                    "No Notes",
                    systemImage: "note.text",
                    description: Text("Tap + to add a note")
                )
                .padding()
            } else {
                List {
                    ForEach(chapterNotes) { note in
                        NavigationLink(destination: DrawingView(note: note)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.title.isEmpty ? "Untitled" : note.title)
                                    .font(.headline)
                                    .lineLimit(1)
                                Text(note.content.isEmpty ? "No content" : note.content)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                                Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            
            // Add note button
            VStack {
                Spacer()
                Button(action: { showingNewNote = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.accentColor)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingNewNote) {
            NavigationStack {
                if let chapter = chapter {
                    DrawingView(chapter: chapter)
                } else {
                    Text("No chapter selected")
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Book.self, 
        Chapter.self, 
        Verse.self, 
        Note.self,
        configurations: config
    )
    
    return MainView()
        .modelContainer(container)
}