//
//  SeedInterlinearData.swift
//  WrittenWord
//
//  Expanded sample interlinear data for demonstrating word lookup feature
//  Includes: John 1:1-14, Genesis 1:1-5, Psalm 23:1-3
//

import Foundation
import SwiftData

@MainActor
func seedExpandedInterlinearData(modelContext: ModelContext) async throws {
    print("📖 Seeding expanded interlinear data...")
    
    // Seed John 1:1-14 (already have 1-5, adding 6-14)
    try await seedJohn1(modelContext: modelContext)
    
    // Seed Genesis 1:1-5
    try await seedGenesis1(modelContext: modelContext)
    
    // Seed Psalm 23:1-3
    try await seedPsalm23(modelContext: modelContext)
    
    print("✅ Expanded interlinear data seeded!")
}

// MARK: - John 1 (verses 1-14)

@MainActor
private func seedJohn1(modelContext: ModelContext) async throws {
    // Find John
    let bookFetch = FetchDescriptor<Book>(
        predicate: #Predicate<Book> { book in book.name == "John" }
    )
    guard let john = try modelContext.fetch(bookFetch).first,
          let chapter1 = john.chapters.first(where: { $0.number == 1 }) else {
        print("⚠️ John 1 not found")
        return
    }
    
    // John 1:6-10 (sample - adding key words)
    
    if let verse6 = chapter1.verses.first(where: { $0.number == 6 }) {
        // "There was a man sent from God, whose name was John."
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("ἄνθρωπος", "anthrōpos", "G444", "man, human", "Noun - Nominative Masculine Singular", 0, 11, 14, "man"),
            ("ἀποστέλλω", "apostellō", "G649", "to send, send away", "Verb - Perfect Passive Participle", 1, 15, 19, "sent"),
            ("θεός", "theos", "G2316", "God", "Noun - Genitive Masculine Singular", 2, 25, 28, "God"),
            ("ὄνομα", "onoma", "G3686", "name", "Noun - Nominative Neuter Singular", 3, 36, 40, "name"),
            ("Ἰωάννης", "Iōannēs", "G2491", "John", "Noun - Nominative Masculine Singular", 4, 45, 49, "John"),
        ]
        addWordsToVerse(verse6, words: words, modelContext: modelContext)
    }
    
    if let verse7 = chapter1.verses.first(where: { $0.number == 7 }) {
        // "The same came for a witness, to bear witness of the Light..."
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("μαρτυρία", "martyria", "G3141", "testimony, witness", "Noun - Accusative Feminine Singular", 0, 19, 26, "witness"),
            ("μαρτυρέω", "martyreō", "G3140", "to testify, bear witness", "Verb - Aorist Active Subjunctive", 1, 31, 43, "bear witness"),
            ("φῶς", "phōs", "G5457", "light", "Noun - Genitive Neuter Singular", 2, 51, 56, "Light"),
        ]
        addWordsToVerse(verse7, words: words, modelContext: modelContext)
    }
    
    if let verse9 = chapter1.verses.first(where: { $0.number == 9 }) {
        // "That was the true Light, which lighteth every man..."
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("ἀληθινός", "alēthinos", "G228", "true, genuine", "Adjective - Nominative Neuter Singular", 0, 13, 17, "true"),
            ("φῶς", "phōs", "G5457", "light", "Noun - Nominative Neuter Singular", 1, 18, 23, "Light"),
            ("φωτίζω", "phōtizō", "G5461", "to give light, illuminate", "Verb - Present Active Indicative", 2, 31, 39, "lighteth"),
            ("ἄνθρωπος", "anthrōpos", "G444", "man, human", "Noun - Accusative Masculine Singular", 3, 46, 49, "man"),
        ]
        addWordsToVerse(verse9, words: words, modelContext: modelContext)
    }
    
    if let verse14 = chapter1.verses.first(where: { $0.number == 14 }) {
        // "And the Word was made flesh, and dwelt among us..."
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("λόγος", "logos", "G3056", "word, speech", "Noun - Nominative Masculine Singular", 0, 8, 12, "Word"),
            ("σάρξ", "sarx", "G4561", "flesh", "Noun - Nominative Feminine Singular", 1, 22, 27, "flesh"),
            ("σκηνόω", "skēnoō", "G4637", "to dwell, tabernacle", "Verb - Aorist Active Indicative", 2, 33, 38, "dwelt"),
            ("δόξα", "doxa", "G1391", "glory", "Noun - Accusative Feminine Singular", 3, 62, 67, "glory"),
            ("μονογενής", "monogenēs", "G3439", "only begotten, unique", "Adjective - Genitive Masculine Singular", 4, 80, 89, "only begotten"),
            ("πατήρ", "patēr", "G3962", "father", "Noun - Genitive Masculine Singular", 5, 101, 107, "Father"),
        ]
        addWordsToVerse(verse14, words: words, modelContext: modelContext)
    }
    
    print("   ✅ John 1 interlinear data added")
}

// MARK: - Genesis 1 (verses 1-5)

@MainActor
private func seedGenesis1(modelContext: ModelContext) async throws {
    // Find Genesis
    let bookFetch = FetchDescriptor<Book>(
        predicate: #Predicate<Book> { book in book.name == "Genesis" }
    )
    guard let genesis = try modelContext.fetch(bookFetch).first,
          let chapter1 = genesis.chapters.first(where: { $0.number == 1 }) else {
        print("⚠️ Genesis 1 not found")
        return
    }
    
    if let verse1 = chapter1.verses.first(where: { $0.number == 1 }) {
        // "In the beginning God created the heaven and the earth."
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("בְּרֵאשִׁית", "bərēʾšîṯ", "H7225", "beginning", "Noun - feminine singular", 0, 7, 16, "beginning"),
            ("בָּרָא", "bārāʾ", "H1254", "to create", "Verb - Qal - Perfect - 3ms", 1, 17, 20, "created"),
            ("אֱלֹהִים", "ʾĕlōhîm", "H430", "God", "Noun - masculine plural", 2, 21, 24, "God"),
            ("שָׁמַיִם", "šāmayim", "H8064", "heaven, sky", "Noun - masculine plural", 3, 36, 42, "heaven"),
            ("אֶרֶץ", "ʾereṣ", "H776", "earth, land", "Noun - feminine singular", 4, 51, 56, "earth"),
        ]
        addWordsToVerse(verse1, words: words, modelContext: modelContext)
    }
    
    if let verse2 = chapter1.verses.first(where: { $0.number == 2 }) {
        // Key words from verse 2
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("תֹהוּ", "ṯōhû", "H8414", "formless, confusion", "Noun - masculine singular", 0, 18, 25, "without form"),
            ("בֹהוּ", "ḇōhû", "H922", "empty", "Noun - masculine singular", 1, 30, 34, "void"),
            ("חֹשֶׁךְ", "ḥōšeḵ", "H2822", "darkness", "Noun - masculine singular", 2, 40, 48, "darkness"),
            ("רוּחַ", "rûaḥ", "H7307", "spirit, wind", "Noun - feminine singular", 3, 77, 83, "Spirit"),
            ("מַיִם", "mayim", "H4325", "water", "Noun - masculine plural", 4, 106, 112, "waters"),
        ]
        addWordsToVerse(verse2, words: words, modelContext: modelContext)
    }
    
    if let verse3 = chapter1.verses.first(where: { $0.number == 3 }) {
        // "And God said, Let there be light: and there was light."
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("אָמַר", "ʾāmar", "H559", "to say", "Verb - Qal - Imperfect - 3ms", 0, 8, 12, "said"),
            ("אוֹר", "ʾôr", "H216", "light", "Noun - masculine singular", 1, 30, 35, "light"),
        ]
        addWordsToVerse(verse3, words: words, modelContext: modelContext)
    }
    
    print("   ✅ Genesis 1 interlinear data added")
}

// MARK: - Psalm 23 (verses 1-3)

@MainActor
private func seedPsalm23(modelContext: ModelContext) async throws {
    // Find Psalms
    let bookFetch = FetchDescriptor<Book>(
        predicate: #Predicate<Book> { book in book.name == "Psalms" }
    )
    guard let psalms = try modelContext.fetch(bookFetch).first,
          let chapter23 = psalms.chapters.first(where: { $0.number == 23 }) else {
        print("⚠️ Psalm 23 not found")
        return
    }
    
    if let verse1 = chapter23.verses.first(where: { $0.number == 1 }) {
        // "The LORD is my shepherd; I shall not want."
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("יְהוָה", "YHWH", "H3068", "LORD, Yahweh", "Noun - proper name", 0, 4, 8, "LORD"),
            ("רָעָה", "rāʿâ", "H7462", "to shepherd, pasture", "Verb - Qal - Participle", 1, 12, 14, "shepherd"),
            ("חָסֵר", "ḥāsēr", "H2637", "to lack, need", "Verb - Qal - Imperfect - 1cs", 2, 33, 37, "want"),
        ]
        addWordsToVerse(verse1, words: words, modelContext: modelContext)
    }
    
    if let verse2 = chapter23.verses.first(where: { $0.number == 2 }) {
        // Key words
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("רָבַץ", "rāḇaṣ", "H7257", "to lie down", "Verb - Hiphil - Imperfect", 0, 8, 16, "lie down"),
            ("דֶּשֶׁא", "dešeʾ", "H1877", "grass, tender grass", "Noun - masculine singular", 1, 20, 25, "green"),
            ("מַיִם", "mayim", "H4325", "water", "Noun - masculine plural", 2, 43, 49, "waters"),
            ("מְנוּחָה", "mənûḥâ", "H4496", "rest, resting place", "Noun - feminine singular", 3, 50, 61, "still"),
        ]
        addWordsToVerse(verse2, words: words, modelContext: modelContext)
    }
    
    if let verse3 = chapter23.verses.first(where: { $0.number == 3 }) {
        // Key words
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("שׁוּב", "šûḇ", "H7725", "to return, restore", "Verb - Polel - Imperfect", 0, 3, 11, "restoreth"),
            ("נֶפֶשׁ", "nefeš", "H5315", "soul, life", "Noun - feminine singular", 1, 15, 19, "soul"),
            ("צֶדֶק", "ṣeḏeq", "H6664", "righteousness", "Noun - masculine singular", 2, 48, 61, "righteousness"),
            ("שֵׁם", "šēm", "H8034", "name", "Noun - masculine singular", 3, 75, 79, "name"),
        ]
        addWordsToVerse(verse3, words: words, modelContext: modelContext)
    }
    
    print("   ✅ Psalm 23 interlinear data added")
}

// MARK: - Helper Function

private func addWordsToVerse(_ verse: Verse, words: [(String, String, String, String, String, Int, Int, Int, String)], modelContext: ModelContext) {
    for w in words {
        let language = w.2.hasPrefix("H") ? "heb" : "grk"
        let word = Word(
            originalText: w.0,
            transliteration: w.1,
            strongsNumber: w.2,
            gloss: w.3,
            morphology: w.4,
            wordIndex: w.5,
            startPosition: w.6,
            endPosition: w.7,
            translatedText: w.8,
            language: language,
            verse: verse
        )
        modelContext.insert(word)
        verse.words.append(word)
    }
}

// MARK: - Integration Instructions
/*
 TO INTEGRATE THIS INTO YOUR APP:
 
 1. Add this file to your Xcode project
 
 2. In WrittenWordApp.swift, find the seedDataIfNeeded function
 
 3. After the main seeding completes (after "✅ Seeding complete!"), add:
 
    // Seed expanded interlinear data
    try await seedExpandedInterlinearData(modelContext: modelContext)
 
 4. This will add interlinear data for:
    - John 1:1-14 (Greek)
    - Genesis 1:1-5 (Hebrew)
    - Psalm 23:1-3 (Hebrew)
 
 5. To test:
    - Navigate to John 1
    - Select a word (e.g., "Word" in verse 1)
    - Word lookup bottom sheet should appear
    - Shows Greek text, transliteration, Strong's number, etc.
 
 EXPANDING THE DATA:
 
 To add more verses/chapters, follow the same pattern:
 - Create a function for each book/chapter
 - Define words array with: (original, transliteration, strongs, gloss, morphology, index, start, end, translated)
 - Call addWordsToVerse
 
 For a COMPLETE interlinear Bible, you would need:
 - A comprehensive database (OpenScriptures, STEPBible, etc.)
 - Import script to process the data
 - ~1GB of interlinear word data
 */
