//
//  WrittenWordApp.swift
//  WrittenWord
//
//  Make sure this is using MainView_Fixed (or MainView_Diagnostic for debugging)
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
            // USE THIS FOR DEBUGGING:
            MainView()
                .modelContainer(sharedModelContainer)
                .task {
                    await seedDataIfNeeded(container: sharedModelContainer)
                }
            
            // THEN SWITCH BACK TO THIS WHEN WORKING:
            // MainView_Fixed()
            //     .modelContainer(sharedModelContainer)
            //     .task {
            //         await seedDataIfNeeded(container: sharedModelContainer)
            //     }
        }
    }
}

@MainActor
func seedDataIfNeeded(container: ModelContainer) async {
    @AppStorage("didSeedData") var didSeedData: Bool = false
    
    print("🌱 Seeding started. didSeedData: \(didSeedData)")
    
    let modelContext = container.mainContext
    do {
        // Check if any books actually exist in the database
        let fetch = FetchDescriptor<Book>(predicate: nil)
        let existing = try modelContext.fetch(fetch)
        print("📚 Existing books count: \(existing.count)")
        
        // Reset seed flag if no books exist but flag says we're seeded
        if existing.isEmpty && didSeedData {
            print("🔄 Resetting seed flag - no books found but flag was true")
            didSeedData = false
        }
        
        guard !didSeedData else {
            print("✅ Already seeded, skipping")
            return
        }

        print("📖 Loading bundled JSON...")
        let data = try loadBundledJSON(named: "kjv", withExtension: "json")
        let decoded = try JSONDecoder().decode([DecodableBook].self, from: data)
        print("✅ Decoded \(decoded.count) books")

        // Define the canonical order of books in the Bible
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

        for (index, b) in decoded.enumerated() {
            print("📝 Seeding book \(index + 1)/\(decoded.count): \(b.name)")
            
            // Determine the testament based on the book name
            let test: String
            if otBooks.contains(b.name) {
                test = "OT"
            } else if ntBooks.contains(b.name) {
                test = "NT"
            } else {
                test = b.testament ?? "OT"
            }
            
            // Determine the order based on the canonical order
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
        
        print("💾 Saving to database...")
        try modelContext.save()
        print("✅ Seeding complete!")

        // Seed sample interlinear data for John 1:1 as a demonstration
        print("📖 Seeding sample interlinear data for John 1:1...")
        try await seedSampleInterlinearData(modelContext: modelContext)

        didSeedData = true

        // Verify
        let savedBooks = try modelContext.fetch(FetchDescriptor<Book>())
        print("📊 Total books in database: \(savedBooks.count)")
        
    } catch {
        print("❌ Seeding failed: \(error)")
    }
}

func loadBundledJSON(named name: String, withExtension ext: String) throws -> Data {
    guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
        print("❌ Failed to find \(name).\(ext) in bundle")
        throw NSError(domain: "Seed", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing bundled JSON \(name).\(ext)"])
    }
    return try Data(contentsOf: url)
}

@MainActor
func seedSampleInterlinearData(modelContext: ModelContext) async throws {
    // Find John 1:1 verse
    // First find the book of John (should be the 4th gospel, order = 43)
    let bookFetch = FetchDescriptor<Book>(
        predicate: #Predicate<Book> { book in
            book.name == "John"
        }
    )
    guard let john = try modelContext.fetch(bookFetch).first else {
        print("⚠️ Book of John not found, skipping interlinear data")
        return
    }

    // Find chapter 1
    guard let chapter1 = john.chapters.first(where: { $0.number == 1 }) else {
        print("⚠️ John chapter 1 not found, skipping interlinear data")
        return
    }

    // Find verse 1
    guard let verse1 = chapter1.verses.first(where: { $0.number == 1 }) else {
        print("⚠️ John 1:1 not found, skipping interlinear data")
        return
    }

    print("📝 Found John 1:1: \(verse1.text)")

    // John 1:1 KJV: "In the beginning was the Word, and the Word was with God, and the Word was God."
    // Greek: "Ἐν ἀρχῇ ἦν ὁ λόγος, καὶ ὁ λόγος ἦν πρὸς τὸν θεόν, καὶ θεὸς ἦν ὁ λόγος."

    // Create interlinear word mappings
    let sampleWords: [(originalText: String, transliteration: String, strongs: String, gloss: String, morphology: String, wordIndex: Int, start: Int, end: Int, translated: String)] = [
        ("Ἐν", "en", "G1722", "in", "Preposition", 0, 0, 2, "In"),
        ("ἀρχῇ", "archē", "G746", "beginning", "Noun - Dative Feminine Singular", 1, 3, 6, "the"),
        ("ἦν", "ēn", "G1510", "was", "Verb - Imperfect Indicative Active - 3rd Person Singular", 2, 7, 10, "beginning"),
        ("ὁ", "ho", "G3588", "the", "Article - Nominative Masculine Singular", 3, 11, 14, "was"),
        ("λόγος", "logos", "G3056", "Word", "Noun - Nominative Masculine Singular", 4, 15, 19, "the Word"),
        ("καὶ", "kai", "G2532", "and", "Conjunction", 5, 19, 20, ","),
        ("ὁ", "ho", "G3588", "the", "Article - Nominative Masculine Singular", 6, 21, 24, "and"),
        ("λόγος", "logos", "G3056", "Word", "Noun - Nominative Masculine Singular", 7, 25, 29, "the Word"),
        ("ἦν", "ēn", "G1510", "was", "Verb - Imperfect Indicative Active - 3rd Person Singular", 8, 30, 33, "was"),
        ("πρὸς", "pros", "G4314", "with", "Preposition", 9, 34, 38, "with"),
        ("τὸν", "ton", "G3588", "the", "Article - Accusative Masculine Singular", 10, 39, 42, ""),
        ("θεόν", "theon", "G2316", "God", "Noun - Accusative Masculine Singular", 11, 43, 46, "God"),
        ("καὶ", "kai", "G2532", "and", "Conjunction", 12, 46, 47, ","),
        ("θεὸς", "theos", "G2316", "God", "Noun - Nominative Masculine Singular", 13, 48, 51, "and"),
        ("ἦν", "ēn", "G1510", "was", "Verb - Imperfect Indicative Active - 3rd Person Singular", 14, 52, 55, "the Word"),
        ("ὁ", "ho", "G3588", "the", "Article - Nominative Masculine Singular", 15, 56, 59, "was"),
        ("λόγος", "logos", "G3056", "Word", "Noun - Nominative Masculine Singular", 16, 60, 64, "God"),
    ]

    for wordData in sampleWords {
        let word = Word(
            originalText: wordData.originalText,
            transliteration: wordData.transliteration,
            strongsNumber: wordData.strongs,
            gloss: wordData.gloss,
            morphology: wordData.morphology,
            wordIndex: wordData.wordIndex,
            startPosition: wordData.start,
            endPosition: wordData.end,
            translatedText: wordData.translated,
            language: "grk",
            verse: verse1
        )
        modelContext.insert(word)
        verse1.words.append(word)
    }

    try modelContext.save()
    print("✅ Sample interlinear data seeded for John 1:1 (\(sampleWords.count) words)")
}

// MARK: - Decoding models matching the bundled JSON
struct DecodableBook: Decodable {
    let name: String
    let abbreviation: String?
    let testament: String?
    let chapters: [DecodableChapter]

    enum CodingKeys: String, CodingKey {
        case name
        case abbreviation
        case abbr
        case shortName
        case testament
        case chapters
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decode(String.self, forKey: .name)
        if let abbr = try container.decodeIfPresent(String.self, forKey: .abbreviation) ??
                      container.decodeIfPresent(String.self, forKey: .abbr) ??
                      container.decodeIfPresent(String.self, forKey: .shortName) {
            self.abbreviation = abbr
        } else {
            self.abbreviation = nil
        }
        self.testament = try container.decodeIfPresent(String.self, forKey: .testament)
        if let chapterObjects = try? container.decode([DecodableChapter].self, forKey: .chapters) {
            self.chapters = chapterObjects
        } else if let chapterArrays = try? container.decode([[DecodableVerse]].self, forKey: .chapters) {
            self.chapters = chapterArrays.enumerated().map { (idx, verses) in
                DecodableChapter(number: idx + 1, verses: verses)
            }
        } else if let chapterStringArrays = try? container.decode([[String]].self, forKey: .chapters) {
            self.chapters = chapterStringArrays.enumerated().map { (cidx, verseStrings) in
                let verses = verseStrings.enumerated().map { (vidx, text) in
                    DecodableVerse(number: vidx + 1, text: text)
                }
                return DecodableChapter(number: cidx + 1, verses: verses)
            }
        } else {
            throw DecodingError.typeMismatch([DecodableChapter].self, DecodingError.Context(codingPath: container.codingPath + [CodingKeys.chapters], debugDescription: "chapters is neither array of objects, array of arrays of verses, nor array of arrays of strings"))
        }
    }
}

struct DecodableChapter: Decodable {
    let number: Int
    let verses: [DecodableVerse]

    init(number: Int, verses: [DecodableVerse]) {
        self.number = number
        self.verses = verses
    }
}

struct DecodableVerse: Decodable {
    let number: Int
    let text: String
}
