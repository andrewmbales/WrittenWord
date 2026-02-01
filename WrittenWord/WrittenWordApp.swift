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
    
    // ⚠️ TEMPORARY: DELETE ALL DATA
    let modelContext = container.mainContext
    do {
        let allBooks = try modelContext.fetch(FetchDescriptor<Book>())
        for book in allBooks {
            modelContext.delete(book)
        }
        try modelContext.save()
        didSeedData = false
        print("🗑️ Deleted all books")
    } catch {
        print("❌ Error: \(error)")
    }
    // ⚠️ END TEMPORARY

    print("🌱 Seeding started. didSeedData: \(didSeedData)")
    
    // let modelContext = container.mainContext
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

        // Seed sample interlinear data for John 1:1-5 as a demonstration
        print("📖 Seeding sample interlinear data for John 1:1-5...")
        try await seedSampleInterlinearData(modelContext: modelContext)

        didSeedData = true

        // Seed expanded interlinear data
print("🔤 Seeding interlinear data...")
try await seedExpandedInterlinearData(modelContext: modelContext)
print("✅ Interlinear data seeded!")

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
    // Find the book of John
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

    var totalWords = 0

    // Seed verse 1
    if let verse1 = chapter1.verses.first(where: { $0.number == 1 }) {
        print("📝 Seeding John 1:1: \(verse1.text)")
        // John 1:1 KJV: "In the beginning was the Word, and the Word was with God, and the Word was God."
        let words1: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("Ἐν", "en", "G1722", "in", "Preposition", 0, 0, 2, "In"),
            ("ἀρχῇ", "archē", "G746", "beginning", "Noun - Dative Feminine Singular", 1, 7, 16, "beginning"),
            ("ἦν", "ēn", "G1510", "was", "Verb - Imperfect Indicative Active - 3rd Person Singular", 2, 17, 20, "was"),
            ("λόγος", "logos", "G3056", "Word", "Noun - Nominative Masculine Singular", 3, 25, 29, "Word"),
            ("λόγος", "logos", "G3056", "Word", "Noun - Nominative Masculine Singular", 4, 39, 43, "Word"),
            ("θεόν", "theon", "G2316", "God", "Noun - Accusative Masculine Singular", 5, 53, 56, "God"),
            ("λόγος", "logos", "G3056", "Word", "Noun - Nominative Masculine Singular", 6, 66, 70, "Word"),
            ("θεός", "theos", "G2316", "God", "Noun - Nominative Masculine Singular", 7, 75, 78, "God"),
        ]
        for w in words1 {
            let word = Word(originalText: w.0, transliteration: w.1, strongsNumber: w.2, gloss: w.3, morphology: w.4, wordIndex: w.5, startPosition: w.6, endPosition: w.7, translatedText: w.8, language: "grk", verse: verse1)
            modelContext.insert(word)
            verse1.words.append(word)
        }
        totalWords += words1.count
    }

    // Seed verse 2
    if let verse2 = chapter1.verses.first(where: { $0.number == 2 }) {
        print("📝 Seeding John 1:2: \(verse2.text)")
        // John 1:2 KJV: "The same was in the beginning with God."
        let words2: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("οὗτος", "houtos", "G3778", "this one", "Demonstrative Pronoun - Nominative Masculine Singular", 0, 4, 8, "same"),
            ("ἦν", "ēn", "G1510", "was", "Verb - Imperfect Indicative Active - 3rd Person Singular", 1, 9, 12, "was"),
            ("ἐν", "en", "G1722", "in", "Preposition", 2, 13, 15, "in"),
            ("ἀρχῇ", "archē", "G746", "beginning", "Noun - Dative Feminine Singular", 3, 20, 29, "beginning"),
            ("πρὸς", "pros", "G4314", "with", "Preposition", 4, 30, 34, "with"),
            ("θεόν", "theon", "G2316", "God", "Noun - Accusative Masculine Singular", 5, 35, 38, "God"),
        ]
        for w in words2 {
            let word = Word(originalText: w.0, transliteration: w.1, strongsNumber: w.2, gloss: w.3, morphology: w.4, wordIndex: w.5, startPosition: w.6, endPosition: w.7, translatedText: w.8, language: "grk", verse: verse2)
            modelContext.insert(word)
            verse2.words.append(word)
        }
        totalWords += words2.count
    }

    // Seed verse 3
    if let verse3 = chapter1.verses.first(where: { $0.number == 3 }) {
        print("📝 Seeding John 1:3: \(verse3.text)")
        // John 1:3 KJV: "All things were made by him; and without him was not any thing made that was made."
        let words3: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("πάντα", "panta", "G3956", "all things", "Adjective - Nominative Neuter Plural", 0, 0, 10, "All things"),
            ("ἐγένετο", "egeneto", "G1096", "came into being", "Verb - Aorist Indicative Middle - 3rd Person Singular", 1, 11, 20, "were made"),
            ("δι'", "di", "G1223", "through", "Preposition", 2, 21, 23, "by"),
            ("αὐτοῦ", "autou", "G846", "him", "Personal Pronoun - Genitive Masculine 3rd Person Singular", 3, 24, 27, "him"),
        ]
        for w in words3 {
            let word = Word(originalText: w.0, transliteration: w.1, strongsNumber: w.2, gloss: w.3, morphology: w.4, wordIndex: w.5, startPosition: w.6, endPosition: w.7, translatedText: w.8, language: "grk", verse: verse3)
            modelContext.insert(word)
            verse3.words.append(word)
        }
        totalWords += words3.count
    }

    // Seed verse 4
    if let verse4 = chapter1.verses.first(where: { $0.number == 4 }) {
        print("📝 Seeding John 1:4: \(verse4.text)")
        // John 1:4 KJV: "In him was life; and the life was the light of men."
        let words4: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("ἐν", "en", "G1722", "in", "Preposition", 0, 0, 2, "In"),
            ("αὐτῷ", "autō", "G846", "him", "Personal Pronoun - Dative Masculine 3rd Person Singular", 1, 3, 6, "him"),
            ("ἦν", "ēn", "G1510", "was", "Verb - Imperfect Indicative Active - 3rd Person Singular", 2, 7, 10, "was"),
            ("ζωὴ", "zōē", "G2222", "life", "Noun - Nominative Feminine Singular", 3, 11, 15, "life"),
            ("ζωὴ", "zōē", "G2222", "life", "Noun - Nominative Feminine Singular", 4, 25, 29, "life"),
            ("φῶς", "phōs", "G5457", "light", "Noun - Nominative Neuter Singular", 5, 38, 43, "light"),
        ]
        for w in words4 {
            let word = Word(originalText: w.0, transliteration: w.1, strongsNumber: w.2, gloss: w.3, morphology: w.4, wordIndex: w.5, startPosition: w.6, endPosition: w.7, translatedText: w.8, language: "grk", verse: verse4)
            modelContext.insert(word)
            verse4.words.append(word)
        }
        totalWords += words4.count
    }

    // Seed verse 5
    if let verse5 = chapter1.verses.first(where: { $0.number == 5 }) {
        print("📝 Seeding John 1:5: \(verse5.text)")
        // John 1:5 KJV: "And the light shineth in darkness; and the darkness comprehended it not."
        let words5: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("καὶ", "kai", "G2532", "and", "Conjunction", 0, 0, 3, "And"),
            ("φῶς", "phōs", "G5457", "light", "Noun - Nominative Neuter Singular", 1, 8, 13, "light"),
            ("φαίνει", "phainei", "G5316", "shines", "Verb - Present Indicative Active - 3rd Person Singular", 2, 14, 21, "shineth"),
            ("σκοτίᾳ", "skotia", "G4653", "darkness", "Noun - Dative Feminine Singular", 3, 25, 33, "darkness"),
        ]
        for w in words5 {
            let word = Word(originalText: w.0, transliteration: w.1, strongsNumber: w.2, gloss: w.3, morphology: w.4, wordIndex: w.5, startPosition: w.6, endPosition: w.7, translatedText: w.8, language: "grk", verse: verse5)
            modelContext.insert(word)
            verse5.words.append(word)
        }
        totalWords += words5.count
    }

    try modelContext.save()
    print("✅ Sample interlinear data seeded for John 1:1-5 (\(totalWords) total words)")
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
