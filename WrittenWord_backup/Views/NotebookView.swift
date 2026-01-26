//
//  NotebookView.swift
//  WrittenWord
//
//  Created by Andrew Bales on 1/21/26.
//
import SwiftUI
import PencilKit
import SwiftData

struct NotebookView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]
    @State private var showingNewNote = false
    @State private var searchText = ""
    @State private var selectedFilter: NoteFilter = .all
    @State private var groupBy: GroupingOption = .date
    @State private var newNote: Note?
    @State private var showingDeleteConfirmation = false
    @State private var notesToDelete: (sectionNotes: [Note], offsets: IndexSet)?
    @State private var cachedFilteredNotes: [Note] = []
    @State private var cachedGroupedNotes: [(String, [Note])] = []
    
    enum NoteFilter: String, CaseIterable {
        case all = "All"
        case chapter = "Chapter"
        case verse = "Verse"
        
        var icon: String {
            switch self {
            case .all: return "square.stack.3d.up"
            case .chapter: return "book"
            case .verse: return "text.quote"
            }
        }
    }
    
    enum GroupingOption: String, CaseIterable {
        case date = "Date"
        case book = "Book"
        case reference = "Reference"
        
        var icon: String {
            switch self {
            case .date: return "calendar"
            case .book: return "book.closed"
            case .reference: return "list.bullet"
            }
        }
    }
    
    var filteredNotes: [Note] {
        let currentNotes = notes
        let currentSearchText = searchText
        let currentFilter = selectedFilter
        
        // Check if we need to recalculate
        if cachedFilteredNotes.isEmpty || 
           cachedFilteredNotes.count != currentNotes.count ||
           !searchText.isEmpty || 
           selectedFilter != .all {
            
            var result = currentNotes
            
            // Apply search filter
            if !currentSearchText.isEmpty {
                result = result.filter { note in
                    note.title.localizedCaseInsensitiveContains(currentSearchText) ||
                    note.content.localizedCaseInsensitiveContains(currentSearchText) ||
                    note.verseReference.localizedCaseInsensitiveContains(currentSearchText)
                }
            }
            
            // Apply type filter
            switch currentFilter {
            case .all:
                break
            case .chapter:
                result = result.filter { $0.verse == nil && $0.chapter != nil }
            case .verse:
                result = result.filter { $0.verse != nil }
            }
            
            cachedFilteredNotes = result
        }
        
        return cachedFilteredNotes
    }
    
    var groupedNotes: [(String, [Note])] {
        let currentFilteredNotes = filteredNotes
        let currentGroupBy = groupBy
        
        // Check if we need to recalculate
        if cachedGroupedNotes.isEmpty || 
           cachedGroupedNotes.map({ $0.1.count }).reduce(0, +) != currentFilteredNotes.count {
            
            switch currentGroupBy {
            case .date:
                cachedGroupedNotes = groupByDate(currentFilteredNotes)
            case .book:
                cachedGroupedNotes = groupByBook(currentFilteredNotes)
            case .reference:
                cachedGroupedNotes = groupByReference(currentFilteredNotes)
            }
        }
        
        return cachedGroupedNotes
    }
    
    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("My Notebook")
                .searchable(text: $searchText, prompt: "Search notes...")
                .toolbar {
                    toolbarContent
                }
                .sheet(isPresented: $showingNewNote) {
                    newNoteSheet
                }
                .alert("Delete Notes", isPresented: $showingDeleteConfirmation) {
                    deleteConfirmationButtons
                } message: {
                    deleteConfirmationMessage
                }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        Group {
            if notes.isEmpty {
                emptyStateView
            } else if filteredNotes.isEmpty {
                noResultsView
            } else {
                notesList
            }
        }
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Notes Yet",
            systemImage: "note.text",
            description: Text("Tap the + button to create your first note")
        )
    }
    
    private var noResultsView: some View {
        ContentUnavailableView(
            "No Results",
            systemImage: "magnifyingglass",
            description: Text("Try a different search or filter")
        )
    }
    
    private var notesList: some View {
        List {
            ForEach(groupedNotes, id: \.0) { section, sectionNotes in
                Section(header: Text(section)) {
                    ForEach(sectionNotes) { note in
                        NavigationLink(destination: FullPageDrawingView(note: note)) {
                            NoteRow(note: note)
                        }
                    }
                    .onDelete { offsets in
                        notesToDelete = (sectionNotes: sectionNotes, offsets: offsets)
                        showingDeleteConfirmation = true
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                newNote = Note(verseReference: "Untitled Note")
                modelContext.insert(newNote!)
                showingNewNote = true
            } label: {
                Label("New Note", systemImage: "plus")
            }
        }
        
        ToolbarItem(placement: .navigationBarLeading) {
            Menu {
                Picker("Filter", selection: $selectedFilter) {
                    ForEach(NoteFilter.allCases, id: \.self) { filter in
                        Label(filter.rawValue, systemImage: filter.icon)
                            .tag(filter)
                    }
                }
                
                Divider()
                
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
    
    @ViewBuilder
    private var newNoteSheet: some View {
        if let newNote = newNote {
            NavigationStack {
                FullPageDrawingView(note: newNote)
            }
        }
    }
    
    @ViewBuilder
    private var deleteConfirmationButtons: some View {
        Button("Cancel", role: .cancel) { }
        Button("Delete", role: .destructive) {
            if let deleteData = notesToDelete {
                deleteNotes(from: deleteData.sectionNotes, offsets: deleteData.offsets)
            }
        }
    }
    
    private var deleteConfirmationMessage: some View {
        Text("Are you sure you want to delete \(notesToDelete?.offsets.count ?? 0) note(s)? This action cannot be undone.")
    }
    
    private func deleteNotes(from sectionNotes: [Note], offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(sectionNotes[index])
            }
        }
    }
    
    // MARK: - Grouping Functions
    
    private func groupByDate(_ notes: [Note]) -> [(String, [Note])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: notes) { note -> String in
            if calendar.isDateInToday(note.updatedAt) {
                return "Today"
            } else if calendar.isDateInYesterday(note.updatedAt) {
                return "Yesterday"
            } else if calendar.isDate(note.updatedAt, equalTo: Date(), toGranularity: .weekOfYear) {
                return "This Week"
            } else if calendar.isDate(note.updatedAt, equalTo: Date(), toGranularity: .month) {
                return "This Month"
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMMM yyyy"
                return formatter.string(from: note.updatedAt)
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
                return first.key < second.key
            }
        }
    }
    
    private func groupByBook(_ notes: [Note]) -> [(String, [Note])] {
        let grouped = Dictionary(grouping: notes) { note -> String in
            if let book = note.chapter?.book {
                return book.name
            } else if let book = note.verse?.chapter?.book {
                return book.name
            } else {
                return "Other"
            }
        }
        
        return grouped.sorted { $0.key < $1.key }
    }
    
    private func groupByReference(_ notes: [Note]) -> [(String, [Note])] {
        let grouped = Dictionary(grouping: notes) { note -> String in
            note.reference
        }
        
        return grouped.sorted { $0.key < $1.key }
    }
}

struct NoteRow: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(note.title.isEmpty ? "Untitled" : note.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                // Badge for note type
                if note.verse != nil {
                    Text("Verse")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                } else if note.chapter != nil {
                    Text("Chapter")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }
            
            Text(note.reference)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            if !note.content.isEmpty {
                Text(note.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                Text(note.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
            }
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
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
    
    // Create sample data
    let context = container.mainContext
    let book = Book(name: "Genesis", order: 1, testament: "OT")
    let chapter = Chapter(number: 1, book: book)
    let verse = Verse(number: 1, text: "In the beginning...", chapter: chapter)
    
    let note1 = Note(title: "Creation Study", verseReference: "Genesis 1:1", chapter: chapter)
    let note2 = Note(title: "God's Power", verseReference: "Genesis 1:1", verse: verse)
    
    context.insert(book)
    context.insert(chapter)
    context.insert(verse)
    context.insert(note1)
    context.insert(note2)
    
    return NotebookView()
        .modelContainer(container)
}