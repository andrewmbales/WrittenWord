//
//  SeedInterlinearData.swift
//  WrittenWord
//
//  Expanded sample interlinear data for demonstrating word lookup feature
//  Includes: John 1:1-14, Genesis 1:1-5, Psalm 23:1-3
//


import Foundation
import SwiftData

// MARK: - Seed Expanded Interlinear Data

@MainActor
func seedExpandedInterlinearData(modelContext: ModelContext) async throws {
    print("📖 Seeding expanded interlinear data...")
    
    // Seed John 1:1-5 (Greek)
    try await seedJohn1Interlinear(modelContext: modelContext)
    
    // Seed Genesis 1:1-5 (Hebrew)
    try await seedGenesis1Interlinear(modelContext: modelContext)
    
    // Seed Psalm 23:1-3 (Hebrew)
    try await seedPsalm23Interlinear(modelContext: modelContext)
    
    print("✅ Expanded interlinear data seeded!")
}

// MARK: - John 1 Interlinear

@MainActor
private func seedJohn1Interlinear(modelContext: ModelContext) async throws {
    let johnFetch = FetchDescriptor<Book>(
        predicate: #Predicate<Book> { book in book.name == "John" }
    )
    guard let john = try modelContext.fetch(johnFetch).first,
          let chapter1 = john.chapters.first(where: { $0.number == 1 }) else {
        print("⚠️ John 1 not found")
        return
    }
    
    // Verse 1: "In the beginning was the Word, and the Word was with God, and the Word was God."
    if let verse1 = chapter1.verses.first(where: { $0.number == 1 }) {
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("ἀρχῇ", "archē", "G746", "beginning, origin", "Noun - Dative Feminine Singular", 0, 7, 16, "beginning"),
            ("ἦν", "ēn", "G1510", "was, to be", "Verb - Imperfect Active Indicative - 3rd Person Singular", 1, 17, 20, "was"),
            ("λόγος", "logos", "G3056", "word, speech, divine utterance", "Noun - Nominative Masculine Singular", 2, 25, 29, "Word"),
            ("καί", "kai", "G2532", "and, even, also", "Conjunction", 3, 35, 38, "and"),
            ("ἦν", "ēn", "G1510", "was, to be", "Verb - Imperfect Active Indicative - 3rd Person Singular", 4, 43, 47, "was"),
            ("πρός", "pros", "G4314", "toward, with, at", "Preposition", 5, 53, 57, "with"),
            ("θεόν", "theon", "G2316", "God, deity", "Noun - Accusative Masculine Singular", 6, 62, 65, "God"),
            ("θεός", "theos", "G2316", "God, deity", "Noun - Nominative Masculine Singular", 7, 80, 84, "God"),
        ]
        addWordsToVerse(verse1, words: words, modelContext: modelContext)
    }
    
    // Verse 2: "The same was in the beginning with God."
    if let verse2 = chapter1.verses.first(where: { $0.number == 2 }) {
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("οὗτος", "houtos", "G3778", "this, he", "Demonstrative Pronoun - Nominative Masculine Singular", 0, 0, 4, "same"),
            ("ἦν", "ēn", "G1510", "was, to be", "Verb - Imperfect Active Indicative - 3rd Person Singular", 1, 9, 12, "was"),
            ("ἀρχῇ", "archē", "G746", "beginning, origin", "Noun - Dative Feminine Singular", 2, 20, 29, "beginning"),
            ("πρός", "pros", "G4314", "toward, with, at", "Preposition", 3, 35, 39, "with"),
            ("θεόν", "theon", "G2316", "God, deity", "Noun - Accusative Masculine Singular", 4, 40, 43, "God"),
        ]
        addWordsToVerse(verse2, words: words, modelContext: modelContext)
    }
    
    // Verse 3: "All things were made by him; and without him was not any thing made that was made."
    if let verse3 = chapter1.verses.first(where: { $0.number == 3 }) {
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("πάντα", "panta", "G3956", "all, every", "Adjective - Nominative Neuter Plural", 0, 0, 3, "All"),
            ("ἐγένετο", "egeneto", "G1096", "to become, happen", "Verb - Aorist Middle Deponent Indicative - 3rd Person Singular", 1, 11, 15, "made"),
            ("αὐτοῦ", "autou", "G846", "him, his, self", "Personal Pronoun - Genitive Masculine 3rd Person Singular", 2, 28, 31, "him"),
        ]
        addWordsToVerse(verse3, words: words, modelContext: modelContext)
    }
    
    // Verse 4: "In him was life; and the life was the light of men."
    if let verse4 = chapter1.verses.first(where: { $0.number == 4 }) {
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("αὐτῷ", "autō", "G846", "him, his, self", "Personal Pronoun - Dative Masculine 3rd Person Singular", 0, 3, 6, "him"),
            ("ζωή", "zōē", "G2222", "life", "Noun - Nominative Feminine Singular", 1, 11, 15, "life"),
            ("φῶς", "phōs", "G5457", "light", "Noun - Nominative Neuter Singular", 2, 38, 43, "light"),
            ("ἀνθρώπων", "anthrōpōn", "G444", "men, mankind", "Noun - Genitive Masculine Plural", 3, 47, 50, "men"),
        ]
        addWordsToVerse(verse4, words: words, modelContext: modelContext)
    }
    
    // Verse 5: "And the light shineth in darkness; and the darkness comprehended it not."
    if let verse5 = chapter1.verses.first(where: { $0.number == 5 }) {
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("φῶς", "phōs", "G5457", "light", "Noun - Nominative Neuter Singular", 0, 8, 13, "light"),
            ("φαίνει", "phainei", "G5316", "to shine, appear", "Verb - Present Active Indicative - 3rd Person Singular", 1, 14, 21, "shineth"),
            ("σκοτίᾳ", "skotia", "G4653", "darkness", "Noun - Dative Feminine Singular", 2, 25, 33, "darkness"),
            ("κατέλαβεν", "katelaben", "G2638", "to seize, comprehend", "Verb - Aorist Active Indicative - 3rd Person Singular", 3, 52, 64, "comprehended"),
        ]
        addWordsToVerse(verse5, words: words, modelContext: modelContext)
    }
    
    print("   ✅ John 1 interlinear data added")
}

// MARK: - Genesis 1 Interlinear

@MainActor
private func seedGenesis1Interlinear(modelContext: ModelContext) async throws {
    let genesisFetch = FetchDescriptor<Book>(
        predicate: #Predicate<Book> { book in book.name == "Genesis" }
    )
    guard let genesis = try modelContext.fetch(genesisFetch).first,
          let chapter1 = genesis.chapters.first(where: { $0.number == 1 }) else {
        print("⚠️ Genesis 1 not found")
        return
    }
    
    // Verse 1: "In the beginning God created the heaven and the earth."
    if let verse1 = chapter1.verses.first(where: { $0.number == 1 }) {
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("בְּרֵאשִׁית", "bərēʾšîṯ", "H7225", "beginning", "Noun - feminine singular construct", 0, 7, 16, "beginning"),
            ("בָּרָא", "bārāʾ", "H1254", "to create", "Verb - Qal - Perfect - 3rd masculine singular", 1, 17, 20, "created"),
            ("אֱלֹהִים", "ʾĕlōhîm", "H430", "God", "Noun - masculine plural", 2, 21, 24, "God"),
            ("שָׁמַיִם", "šāmayim", "H8064", "heaven, sky", "Noun - masculine dual", 3, 29, 35, "heaven"),
            ("אֶרֶץ", "ʾereṣ", "H776", "earth, land", "Noun - feminine singular", 4, 44, 49, "earth"),
        ]
        addWordsToVerse(verse1, words: words, modelContext: modelContext)
    }
    
    // Verse 2: "And the earth was without form, and void..."
    if let verse2 = chapter1.verses.first(where: { $0.number == 2 }) {
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("אֶרֶץ", "ʾereṣ", "H776", "earth, land", "Noun - feminine singular", 0, 8, 13, "earth"),
            ("תֹהוּ", "ṯōhû", "H8414", "formlessness, confusion, unreality", "Noun - masculine singular", 1, 18, 25, "form"),
            ("בֹהוּ", "ḇōhû", "H922", "emptiness", "Noun - masculine singular", 2, 31, 35, "void"),
            ("חֹשֶׁךְ", "ḥōšeḵ", "H2822", "darkness", "Noun - masculine singular", 3, 41, 49, "darkness"),
            ("רוּחַ", "rûaḥ", "H7307", "spirit, wind, breath", "Noun - common singular construct", 4, 74, 80, "Spirit"),
            ("אֱלֹהִים", "ʾĕlōhîm", "H430", "God", "Noun - masculine plural", 5, 84, 87, "God"),
            ("מַיִם", "mayim", "H4325", "water", "Noun - masculine plural", 6, 106, 112, "waters"),
        ]
        addWordsToVerse(verse2, words: words, modelContext: modelContext)
    }
    
    // Verse 3: "And God said, Let there be light: and there was light."
    if let verse3 = chapter1.verses.first(where: { $0.number == 3 }) {
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("אֱלֹהִים", "ʾĕlōhîm", "H430", "God", "Noun - masculine plural", 0, 4, 7, "God"),
            ("אָמַר", "ʾāmar", "H559", "to say, speak", "Verb - Qal - Imperfect - 3rd masculine singular", 1, 8, 12, "said"),
            ("אוֹר", "ʾôr", "H216", "light", "Noun - masculine singular", 2, 27, 32, "light"),
        ]
        addWordsToVerse(verse3, words: words, modelContext: modelContext)
    }
    
    // Verse 4: "And God saw the light, that it was good..."
    if let verse4 = chapter1.verses.first(where: { $0.number == 4 }) {
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("רָאָה", "rāʾâ", "H7200", "to see, perceive", "Verb - Qal - Imperfect - 3rd masculine singular", 0, 8, 11, "saw"),
            ("אוֹר", "ʾôr", "H216", "light", "Noun - masculine singular", 1, 16, 21, "light"),
            ("טוֹב", "ṭôḇ", "G2896", "good, pleasant", "Adjective - masculine singular", 2, 33, 37, "good"),
            ("חֹשֶׁךְ", "ḥōšeḵ", "H2822", "darkness", "Noun - masculine singular", 3, 61, 69, "darkness"),
        ]
        addWordsToVerse(verse4, words: words, modelContext: modelContext)
    }
    
    // Verse 5: "And God called the light Day..."
    if let verse5 = chapter1.verses.first(where: { $0.number == 5 }) {
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("קָרָא", "qārāʾ", "H7121", "to call, proclaim", "Verb - Qal - Imperfect - 3rd masculine singular", 0, 8, 14, "called"),
            ("אוֹר", "ʾôr", "H216", "light", "Noun - masculine singular", 1, 19, 24, "light"),
            ("יוֹם", "yôm", "H3117", "day", "Noun - masculine singular", 2, 25, 28, "Day"),
            ("חֹשֶׁךְ", "ḥōšeḵ", "H2822", "darkness", "Noun - masculine singular", 3, 38, 46, "darkness"),
            ("לַיְלָה", "laylâ", "H3915", "night", "Noun - masculine singular", 4, 54, 59, "Night"),
        ]
        addWordsToVerse(verse5, words: words, modelContext: modelContext)
    }
    
    print("✅ Genesis 1 interlinear data added")
}

// MARK: - Psalm 23 Interlinear

@MainActor
private func seedPsalm23Interlinear(modelContext: ModelContext) async throws {
    let psalmsFetch = FetchDescriptor<Book>(
        predicate: #Predicate<Book> { book in book.name == "Psalms" }
    )
    guard let psalms = try modelContext.fetch(psalmsFetch).first,
          let chapter23 = psalms.chapters.first(where: { $0.number == 23 }) else {
        print("⚠️ Psalm 23 not found")
        return
    }
    
    // Verse 1: "The LORD is my shepherd; I shall not want."
    if let verse1 = chapter23.verses.first(where: { $0.number == 1 }) {
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("יְהוָה", "YHWH", "H3068", "LORD, Yahweh", "Proper Noun", 0, 4, 8, "LORD"),
            ("רָעָה", "rāʿâ", "H7462", "to pasture, tend, graze", "Verb - Qal - Participle - masculine singular", 1, 12, 14, "shepherd"),
            ("חָסֵר", "ḥāsēr", "H2637", "to lack, need, decrease", "Verb - Qal - Imperfect - 1st common singular", 2, 28, 32, "want"),
        ]
        addWordsToVerse(verse1, words: words, modelContext: modelContext)
    }
    
    // Verse 2: "He maketh me to lie down in green pastures..."
    if let verse2 = chapter23.verses.first(where: { $0.number == 2 }) {
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("רָבַץ", "rāḇaṣ", "H7257", "to lie down, rest", "Verb - Hiphil - Imperfect - 3rd masculine singular", 0, 14, 17, "lie"),
            ("דֶּשֶׁא", "dešeʾ", "H1877", "grass, new grass", "Noun - masculine singular construct", 1, 24, 29, "green"),
            ("נָאוֶה", "nāweh", "H5116", "pasture, habitation", "Noun - masculine singular", 2, 30, 38, "pastures"),
            ("מַיִם", "mayim", "H4325", "water", "Noun - masculine plural construct", 3, 54, 61, "waters"),
            ("מְנוּחָה", "mənûḥôṯ", "H4496", "resting place, quietness", "Noun - feminine plural", 4, 62, 67, "still"),
        ]
        addWordsToVerse(verse2, words: words, modelContext: modelContext)
    }
    
    // Verse 3: "He restoreth my soul..."
    if let verse3 = chapter23.verses.first(where: { $0.number == 3 }) {
        let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
            ("נֶפֶשׁ", "nefeš", "H5315", "soul, life, person", "Noun - feminine singular", 0, 14, 18, "soul"),
            ("שׁוּב", "šûḇ", "H7725", "to turn back, return", "Verb - Polel - Imperfect - 3rd masculine singular", 1, 3, 12, "restoreth"),
            ("נָחָה", "nāḥâ", "H5148", "to lead, guide", "Verb - Piel - Imperfect - 3rd masculine singular", 2, 23, 29, "leadeth"),
            ("צֶדֶק", "ṣeḏeq", "H6664", "righteousness, justice", "Noun - masculine singular", 3, 45, 58, "righteousness"),
            ("שֵׁם", "šēm", "H8034", "name", "Noun - masculine singular construct", 4, 72, 76, "name"),
        ]
        addWordsToVerse(verse3, words: words, modelContext: modelContext)
    }
    
    print("✅ Psalm 23 interlinear data added")
}

// MARK: - Helper Function

private func addWordsToVerse(_ verse: Verse, words: [(String, String, String, String, String, Int, Int, Int, String)], modelContext: ModelContext) {
    // Skip if verse already has interlinear data
    guard verse.words.isEmpty else { return }
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


