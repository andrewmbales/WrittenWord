//
//  AddBookmarkSheet.swift
//  WrittenWord
//
//  Phase 2: Quick bookmark creation
//
import SwiftUI
import SwiftData

struct AddBookmarkSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let verse: Verse?
    let chapter: Chapter?
    
    @State private var title: String = ""
    @State private var selectedCategory: BookmarkCategory = .general
    @State private var notes: String = ""
    @State private var isPinned: Bool = false
    
    init(verse: Verse) {
        self.verse = verse
        self.chapter = nil
        _title = State(initialValue: "")
    }
    
    init(chapter: Chapter) {
        self.verse = nil
        self.chapter = chapter
        _title = State(initialValue: "")
    }
    
    var referenceText: String {
        if let verse = verse {
            return verse.reference
        } else if let chapter = chapter {
            return chapter.reference
        }
        return "Unknown"
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Reference") {
                    Text(referenceText)
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                
                Section("Details") {
                    TextField("Title (optional)", text: $title)
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(BookmarkCategory.allCases) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                    
                    Toggle("Pin to Top", isOn: $isPinned)
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
                
                Section {
                    Button("Save Bookmark") {
                        saveBookmark()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("New Bookmark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func saveBookmark() {
        let bookmark = Bookmark(
            title: title,
            verse: verse,
            chapter: chapter,
            category: selectedCategory.rawValue,
            color: selectedCategory.color,
            notes: notes,
            isPinned: isPinned
        )
        
        modelContext.insert(bookmark)
        try? modelContext.save()
        
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Verse.self,
        Chapter.self,
        Book.self,
        Bookmark.self,
        configurations: config
    )
    
    let book = Book(name: "John", order: 43, testament: "NT")
    let chapter = Chapter(number: 3, book: book)
    let verse = Verse(number: 16, text: "For God so loved the world...", chapter: chapter)
    
    return AddBookmarkSheet(verse: verse)
        .modelContainer(container)
}