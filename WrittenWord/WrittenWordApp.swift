//
//  WrittenWordApp.swift
//  WrittenWord
//
//  Proper seed-once logic with debug prints gated
//

import SwiftUI
import SwiftData

@main
struct WrittenWordApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Book.self,
            Chapter.self,
            Verse.self,
            Word.self,
            Note.self,
            Highlight.self,
            Bookmark.self,
            Item.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .modelContainer(sharedModelContainer)
                .task {
                    await seedDataIfNeeded(container: sharedModelContainer)
                }
        }
    }
}

// MARK: - Seeding Logic

@MainActor
func seedDataIfNeeded(container: ModelContainer) async {
    @AppStorage("didSeedData") var didSeedData: Bool = false
    
    let modelContext = container.mainContext
    
    do {
        // Check if any books actually exist in the database
        let fetch = FetchDescriptor<Book>(predicate: nil)
        let existing = try modelContext.fetch(fetch)
        
        debugLog("data", "📚 Database check - Books: \(existing.count), Seed flag: \(didSeedData)")
        
        // If we have books AND the flag is set, we're done
        if !existing.isEmpty && didSeedData {
            debugLog("data", "✅ Database already seeded, skipping")
            return
        }
        
        // If flag says seeded but no books exist, reset flag
        if existing.isEmpty && didSeedData {
            debugLog("data", "🔄 Resetting seed flag - no books found")
            didSeedData = false
        }
        
        // If books exist but flag not set, just set the flag (recovered state)
        if !existing.isEmpty && !didSeedData {
            debugLog("data", "🔄 Books exist but flag not set - setting flag")
            didSeedData = true
            return
        }
        
        // Only seed if we have no books and flag is false
        guard existing.isEmpty && !didSeedData else {
            return
        }
        
        debugLog("data", "🌱 Starting fresh database seed...")
        
        // Load and decode Bible JSON
        debugLog("data", "📖 Loading bundled JSON...")
        let data = try loadBundledJSON(named: "kjv", withExtension: "json")
        
        if DebugConfig.Categories.dataLoading {
            if let jsonString = String(data: data, encoding: .utf8) {
                debugLog("data", "📄 JSON Preview (first 500 chars): \(String(jsonString.prefix(500)))...")
            }
        }
        
        let decoded = try JSONDecoder().decode([DecodableBook].self, from: data)
        debugLog("data", "✅ Decoded \(decoded.count) books")

        // Define the canonical order of books
        let otBooks = [
            "Genesis", "Exodus", "Leviticus", "Numbers", "Deuteronomy",
            "Joshua", "Judges", "Ruth", "1 Samuel", "2 Samuel",
            "1 Kings", "2 Kings", "1 Chronicles", "2 Chronicles", "Ezra",
            "Nehemiah", "Esther", "Job", "Psalms", "Proverbs",
            "Ecclesiastes", "Song of Solomon", "Isaiah", "Jeremiah", "Lamentations",
            "Ezekiel", "Daniel", "Hosea", "Joel", "Amos",
            "Obadiah", "Jonah", "Micah", "Nahum", "Habakkuk",
            "Zephaniah", "Haggai", "Zechariah", "Malachi"
        ]
        
        let ntBooks = [
            "Matthew", "Mark", "Luke", "John", "Acts",
            "Romans", "1 Corinthians", "2 Corinthians", "Galatians", "Ephesians",
            "Philippians", "Colossians", "1 Thessalonians", "2 Thessalonians", "1 Timothy",
            "2 Timothy", "Titus", "Philemon", "Hebrews", "James",
            "1 Peter", "2 Peter", "1 John", "2 John", "3 John",
            "Jude", "Revelation"
        ]

        // Seed all books
        for (index, b) in decoded.enumerated() {
            debugLog("data", "📝 Seeding book \(index + 1)/\(decoded.count): \(b.name)")
            
            // Determine testament
            let test: String
            if otBooks.contains(b.name) {
                test = "OT"
            } else if ntBooks.contains(b.name) {
                test = "NT"
            } else {
                test = b.testament ?? "OT"
            }
            
            // Determine order
            let order: Int
            if let otIndex = otBooks.firstIndex(of: b.name) {
                order = otIndex + 1
            } else if let ntIndex = ntBooks.firstIndex(of: b.name) {
                order = otBooks.count + ntIndex + 1
            } else {
                order = index + 1
            }
            
            let book = Book(name: b.name, order: order, testament: test)
            modelContext.insert(book)
            
            let sortedChapters = b.chapters.sorted { $0.number < $1.number }
            for ch in sortedChapters {
                let chapter = Chapter(number: ch.number, book: book)
                modelContext.insert(chapter)
                
                let sortedVerses = ch.verses.sorted { $0.number < $1.number }
                for v in sortedVerses {
                    let verse = Verse(number: v.number, text: v.text, version: "KJV", chapter: chapter)
                    modelContext.insert(verse)
                    chapter.verses.append(verse)
                }
                book.chapters.append(chapter)
            }
        }
        
        debugLog("data", "💾 Saving to database...")
        try modelContext.save()
        debugLog("data", "✅ Bible text seeding complete!")

        // Seed interlinear data
        debugLog("data", "🔤 Seeding interlinear data from JSON...")
        try await seedInterlinearData(modelContext: modelContext)
        debugLog("data", "✅ Interlinear data seeded!")
        
        // Mark as complete
        didSeedData = true
        
        // Verify
        let savedBooks = try modelContext.fetch(FetchDescriptor<Book>())
        debugLog("data", "📊 Final check - Total books: \(savedBooks.count)")
        debugLog("data", "🎉 Database initialization complete!")
        
    } catch {
        print("❌ Seeding failed: \(error)")
    }
}

// MARK: - Helper Functions

func loadBundledJSON(named name: String, withExtension ext: String) throws -> Data {
    guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
        debugLog("data", "❌ Failed to find \(name).\(ext) in bundle")
        throw NSError(domain: "Seed", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing bundled JSON \(name).\(ext)"])
    }
    return try Data(contentsOf: url)
}

// MARK: - Decodable Models
struct DecodableBook: Decodable {
    let name: String
    let abbrev: String
    let testament: String?
    let chapters: [DecodableChapter]
    
    enum CodingKeys: String, CodingKey {
        case name
        case abbrev
        case testament
        case chapters
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        name = try container.decode(String.self, forKey: .name)
        abbrev = try container.decode(String.self, forKey: .abbrev)
        testament = try? container.decode(String.self, forKey: .testament)
        
        // Decode chapters as array of string arrays
        let versesArrays = try container.decode([[String]].self, forKey: .chapters)
        
        chapters = versesArrays.enumerated().map { chapterIndex, verses in
            let decodedVerses = verses.enumerated().map { verseIndex, text in
                DecodableVerse(number: verseIndex + 1, text: text)
            }
            return DecodableChapter(number: chapterIndex + 1, verses: decodedVerses)
        }
    }
}

struct DecodableChapter: Decodable {
    let number: Int
    let verses: [DecodableVerse]
}

struct DecodableVerse: Decodable {
    let number: Int
    let text: String
}
