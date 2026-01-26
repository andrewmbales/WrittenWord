//
//  MainView.swift
//  WrittenWord
//
//  Enhanced version with improved UI/UX
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
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        Group {
            if notePosition == .right {
                notesOnRightLayout
            } else {
                notesOnLeftLayout
            }
        }
        .onChange(of: selectedChapter) { oldValue, newValue in
            if newValue != nil {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    columnVisibility = .detailOnly
                }
            } else if selectedBook != nil {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    columnVisibility = .all
                }
            }
        }
        .onChange(of: selectedBook) { oldValue, newValue in
            selectedChapter = nil
            withAnimation(.easeOut(duration: 0.2)) {
                showingNoteColumn = false
            }
            if newValue == nil {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    columnVisibility = .all
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .showNotesColumn)) { notification in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                showingNoteColumn = true
            }
        }
    }
    
    private var notesOnRightLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selectedBook: $selectedBook)
        } content: {
            if let selectedBook {
                ChapterListView(book: selectedBook, selectedChapter: $selectedChapter)
                    .transition(.opacity)
            } else {
                ContentUnavailableView(
                    "Select a Book",
                    systemImage: "book.closed.fill",
                    description: Text("Choose a book from the sidebar to begin reading")
                )
            }
        } detail: {
            if let selectedChapter {
                ChapterView(chapter: selectedChapter, onChapterChange: navigateToChapter)
                    .frame(maxWidth: .infinity)
                    .onAppear {
                        // Ensure columns are minimized when chapter is selected
                        if columnVisibility != .detailOnly {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                columnVisibility = .detailOnly
                            }
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else {
                ContentUnavailableView(
                    "Select a Chapter",
                    systemImage: "book.pages.fill",
                    description: Text("Choose a chapter to read")
                )
                    .frame(maxWidth: .infinity)
                }
        }
    }
    
    private func navigateToChapter(_ chapter: Chapter) {
        print("navigateToChapter called: \(chapter.book?.name ?? "") \(chapter.number)")
        selectedChapter = chapter
        navigationPath = NavigationPath()
    }
    
    private var notesOnLeftLayout: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView(selectedBook: $selectedBook)
        } content: {
            if showingNoteColumn {
                NotesColumn(
                    chapter: selectedChapter,
                    onClose: { 
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showingNoteColumn = false
                        }
                    }
                )
                .transition(.move(edge: .leading).combined(with: .opacity))
            } else if let selectedBook {
                ChapterListView(book: selectedBook, selectedChapter: $selectedChapter)
                    .transition(.opacity)
            } else {
                ContentUnavailableView(
                    "Select a Book",
                    systemImage: "book.closed.fill",
                    description: Text("Choose a book from the sidebar to begin reading")
                )
            }
        } detail: {
            if let selectedChapter {
                ChapterView(chapter: selectedChapter, onChapterChange: navigateToChapter)
                    .frame(maxWidth: .infinity)
                    .onAppear {
                        // Ensure columns are minimized when chapter is selected
                        if columnVisibility != .detailOnly {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                columnVisibility = .detailOnly
                            }
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else {
                ContentUnavailableView(
                    "Select a Chapter",
                    systemImage: "book.pages.fill",
                    description: Text("Choose a chapter to read")
                )
                .frame(maxWidth: .infinity)
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

struct NoteCard: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.title.isEmpty ? "Untitled Note" : note.title)
                .font(.headline)
                .lineLimit(2)
                .foregroundStyle(.primary)
            
            if !note.content.isEmpty {
                Text(note.content)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
            
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
            }
            .foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
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
            HStack {
                Text("Notes")
                    .font(.title3.bold())
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(.ultraThinMaterial)
            
            Divider()
            
            if chapterNotes.isEmpty {
                ContentUnavailableView {
                    Label("No Notes", systemImage: "note.text")
                } description: {
                    Text("Tap the + button to create your first note")
                }
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(chapterNotes) { note in
                            NavigationLink(destination: FullPageDrawingView(note: note)) {
                                NoteCard(note: note)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
            
            Divider()
            
            HStack {
                Spacer()
                Button(action: { showingNewNote = true }) {
                    Label("New Note", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingNewNote) {
            NavigationStack {
                if let chapter = chapter {
                    FullPageDrawingView(chapter: chapter)
                } else {
                    Text("No chapter selected")
                }
            }
        }
    }
}