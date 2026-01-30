//
//  LexiconEntry.swift
//  WrittenWord
//
//  Model for lexicon/dictionary entries with structured definitions
//

import Foundation

/// A complete lexicon entry with multiple definitions and verse references
struct LexiconEntry: Identifiable, Codable {
    let id: UUID
    let strongsNumber: String
    let originalText: String
    let transliteration: String
    let partOfSpeechLabel: String // e.g., "ἄγγελος, -ου, ὁ, in LXX"
    let definitions: [Definition]
    let totalOccurrences: Int
    let source: String // e.g., "Abbott-Smith. A Manual Greek Lexicon of the New Testament. Sourced from Tyndale House, Cambridge."

    init(
        id: UUID = UUID(),
        strongsNumber: String,
        originalText: String,
        transliteration: String,
        partOfSpeechLabel: String,
        definitions: [Definition],
        totalOccurrences: Int,
        source: String
    ) {
        self.id = id
        self.strongsNumber = strongsNumber
        self.originalText = originalText
        self.transliteration = transliteration
        self.partOfSpeechLabel = partOfSpeechLabel
        self.definitions = definitions
        self.totalOccurrences = totalOccurrences
        self.source = source
    }
}

/// A single definition with optional sub-definitions and verse references
struct Definition: Identifiable, Codable {
    let id: UUID
    let number: Int
    let meaning: String
    let verseReferences: [VerseReference]
    let subDefinitions: [SubDefinition]

    init(
        id: UUID = UUID(),
        number: Int,
        meaning: String,
        verseReferences: [VerseReference] = [],
        subDefinitions: [SubDefinition] = []
    ) {
        self.id = id
        self.number = number
        self.meaning = meaning
        self.verseReferences = verseReferences
        self.subDefinitions = subDefinitions
    }
}

/// A sub-definition with a letter identifier
struct SubDefinition: Identifiable, Codable {
    let id: UUID
    let letter: String // "a", "b", "c", "d", etc.
    let meaning: String
    let verseReferences: [VerseReference]

    init(
        id: UUID = UUID(),
        letter: String,
        meaning: String,
        verseReferences: [VerseReference] = []
    ) {
        self.id = id
        self.letter = letter
        self.meaning = meaning
        self.verseReferences = verseReferences
    }
}

/// A reference to a Bible verse (e.g., "Mat 11:10", "Luk 1:11")
struct VerseReference: Identifiable, Codable, Hashable {
    let id: UUID
    let book: String // Abbreviated book name (e.g., "Mat", "Luk", "Jhn")
    let chapter: Int
    let verse: Int

    init(
        id: UUID = UUID(),
        book: String,
        chapter: Int,
        verse: Int
    ) {
        self.id = id
        self.book = book
        self.chapter = chapter
        self.verse = verse
    }

    /// Formatted display (e.g., "Mat 11:10")
    var display: String {
        "\(book) \(chapter):\(verse)"
    }

    /// Full book name mapping
    var fullBookName: String {
        BookAbbreviations.fullName(for: book)
    }
}

/// Helper for book abbreviation mapping
enum BookAbbreviations {
    static let mapping: [String: String] = [
        "Gen": "Genesis",
        "Exo": "Exodus",
        "Lev": "Leviticus",
        "Num": "Numbers",
        "Deu": "Deuteronomy",
        "Jos": "Joshua",
        "Jdg": "Judges",
        "Rut": "Ruth",
        "1Sa": "1 Samuel",
        "2Sa": "2 Samuel",
        "1Ki": "1 Kings",
        "2Ki": "2 Kings",
        "1Ch": "1 Chronicles",
        "2Ch": "2 Chronicles",
        "Ezr": "Ezra",
        "Neh": "Nehemiah",
        "Est": "Esther",
        "Job": "Job",
        "Psa": "Psalms",
        "Pro": "Proverbs",
        "Ecc": "Ecclesiastes",
        "Sol": "Song of Solomon",
        "Isa": "Isaiah",
        "Jer": "Jeremiah",
        "Lam": "Lamentations",
        "Eze": "Ezekiel",
        "Dan": "Daniel",
        "Hos": "Hosea",
        "Joe": "Joel",
        "Amo": "Amos",
        "Oba": "Obadiah",
        "Jon": "Jonah",
        "Mic": "Micah",
        "Nah": "Nahum",
        "Hab": "Habakkuk",
        "Zep": "Zephaniah",
        "Hag": "Haggai",
        "Zec": "Zechariah",
        "Mal": "Malachi",
        "Mat": "Matthew",
        "Mar": "Mark",
        "Luk": "Luke",
        "Jhn": "John",
        "Act": "Acts",
        "Rom": "Romans",
        "1Co": "1 Corinthians",
        "2Co": "2 Corinthians",
        "Gal": "Galatians",
        "Eph": "Ephesians",
        "Php": "Philippians",
        "Col": "Colossians",
        "1Th": "1 Thessalonians",
        "2Th": "2 Thessalonians",
        "1Ti": "1 Timothy",
        "2Ti": "2 Timothy",
        "Tit": "Titus",
        "Phm": "Philemon",
        "Heb": "Hebrews",
        "Jas": "James",
        "1Pe": "1 Peter",
        "2Pe": "2 Peter",
        "1Jn": "1 John",
        "2Jn": "2 John",
        "3Jn": "3 John",
        "Jud": "Jude",
        "Rev": "Revelation"
    ]

    static func fullName(for abbreviation: String) -> String {
        mapping[abbreviation] ?? abbreviation
    }
}
