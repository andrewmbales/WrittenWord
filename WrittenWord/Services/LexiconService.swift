//
//  LexiconService.swift
//  WrittenWord
//
//  Service for retrieving lexicon/dictionary entries for original language words
//

import Foundation
import SwiftData

class LexiconService {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Get a lexicon entry for a given word
    func getLexiconEntry(for word: Word) -> LexiconEntry? {
        guard let strongsNumber = word.strongsNumber else { return nil }

        // In a production app, this would query a lexicon database
        // For now, we'll return sample data or generate from existing word data
        return getSampleLexiconEntry(for: word)
    }

    /// Count occurrences of a word across all verses by Strong's number
    func countOccurrences(for strongsNumber: String) -> Int {
        let descriptor = FetchDescriptor<Word>(
            predicate: #Predicate { word in
                word.strongsNumber == strongsNumber
            }
        )

        do {
            let words = try modelContext.fetch(descriptor)
            return words.count
        } catch {
            print("Error counting occurrences: \(error)")
            return 0
        }
    }

    /// Get all verse references where this word appears
    func getVerseReferences(for strongsNumber: String, limit: Int = 20) -> [VerseReference] {
        let descriptor = FetchDescriptor<Word>(
            predicate: #Predicate { word in
                word.strongsNumber == strongsNumber
            }
        )

        do {
            let words = try modelContext.fetch(descriptor)
            var references: [VerseReference] = []

            for word in words.prefix(limit) {
                if let verse = word.verse,
                   let chapter = verse.chapter,
                   let book = chapter.book {
                    let ref = VerseReference(
                        book: abbreviateBookName(book.name),
                        chapter: chapter.number,
                        verse: verse.number
                    )
                    references.append(ref)
                }
            }

            return references
        } catch {
            print("Error fetching verse references: \(error)")
            return []
        }
    }

    // MARK: - Sample Data Generation

    /// Generate a sample lexicon entry from word data
    private func getSampleLexiconEntry(for word: Word) -> LexiconEntry {
        let strongsNumber = word.strongsNumber ?? "Unknown"
        let occurrences = countOccurrences(for: strongsNumber)
        let verseRefs = getVerseReferences(for: strongsNumber, limit: 10)

        // Get sample data based on known Strong's numbers, or use generic data
        if let sampleEntry = getSampleDataForStrongsNumber(strongsNumber, word: word) {
            return sampleEntry
        }

        // Generic fallback
        let parsed = word.morphology != nil ? MorphologyParser.parse(word.morphology!) : nil
        let posLabel = "\(word.originalText), \(parsed?.partOfSpeech.lowercased() ?? "n.")"

        return LexiconEntry(
            strongsNumber: strongsNumber,
            originalText: word.originalText,
            transliteration: word.transliteration,
            partOfSpeechLabel: posLabel,
            definitions: [
                Definition(
                    number: 1,
                    meaning: word.gloss,
                    verseReferences: Array(verseRefs.prefix(5))
                )
            ],
            totalOccurrences: occurrences,
            source: "Abbott-Smith. A Manual Greek Lexicon of the New Testament. Sourced from Tyndale House, Cambridge."
        )
    }

    /// Get rich sample data for specific Strong's numbers
    private func getSampleDataForStrongsNumber(_ strongsNumber: String, word: Word) -> LexiconEntry? {
        let occurrences = countOccurrences(for: strongsNumber)
        let verseRefs = getVerseReferences(for: strongsNumber, limit: 15)

        switch strongsNumber {
        case "G32": // ἄγγελος (angelos) - angel/messenger
            return LexiconEntry(
                strongsNumber: "G32",
                originalText: "ἄγγελος",
                transliteration: "angelos",
                partOfSpeechLabel: "ἄγγελος, -ου, ὁ, in LXX",
                definitions: [
                    Definition(
                        number: 1,
                        meaning: "a messenger",
                        verseReferences: Array(verseRefs.prefix(3)),
                        subDefinitions: [
                            SubDefinition(
                                letter: "a",
                                meaning: "in general",
                                verseReferences: [
                                    VerseReference(book: "Mat", chapter: 11, verse: 10),
                                    VerseReference(book: "Luk", chapter: 7, verse: 24)
                                ]
                            ),
                            SubDefinition(
                                letter: "b",
                                meaning: "specially, of the messengers of God",
                                verseReferences: [
                                    VerseReference(book: "Mat", chapter: 1, verse: 20),
                                    VerseReference(book: "Luk", chapter: 1, verse: 11)
                                ]
                            )
                        ]
                    ),
                    Definition(
                        number: 2,
                        meaning: "an angel, a celestial spirit",
                        verseReferences: Array(verseRefs.dropFirst(3).prefix(4)),
                        subDefinitions: [
                            SubDefinition(
                                letter: "a",
                                meaning: "of God's messengers",
                                verseReferences: [
                                    VerseReference(book: "Mat", chapter: 4, verse: 11),
                                    VerseReference(book: "Mat", chapter: 28, verse: 2)
                                ]
                            ),
                            SubDefinition(
                                letter: "b",
                                meaning: "of the devil's angels",
                                verseReferences: [
                                    VerseReference(book: "Mat", chapter: 25, verse: 41),
                                    VerseReference(book: "Rev", chapter: 12, verse: 7)
                                ]
                            )
                        ]
                    )
                ],
                totalOccurrences: occurrences > 0 ? occurrences : 172,
                source: "Abbott-Smith. A Manual Greek Lexicon of the New Testament. Sourced from Tyndale House, Cambridge."
            )

        case "G2316": // θεός (theos) - God
            return LexiconEntry(
                strongsNumber: "G2316",
                originalText: "θεός",
                transliteration: "theos",
                partOfSpeechLabel: "θεός, -οῦ, ὁ, in LXX",
                definitions: [
                    Definition(
                        number: 1,
                        meaning: "a god or goddess, a general name of deities or divinities",
                        verseReferences: [
                            VerseReference(book: "Act", chapter: 7, verse: 43),
                            VerseReference(book: "Act", chapter: 19, verse: 26),
                            VerseReference(book: "1Co", chapter: 8, verse: 5)
                        ]
                    ),
                    Definition(
                        number: 2,
                        meaning: "God, the Godhead, trinity",
                        verseReferences: Array(verseRefs.prefix(5)),
                        subDefinitions: [
                            SubDefinition(
                                letter: "a",
                                meaning: "of the true God",
                                verseReferences: [
                                    VerseReference(book: "Jhn", chapter: 1, verse: 1),
                                    VerseReference(book: "Rom", chapter: 1, verse: 7)
                                ]
                            ),
                            SubDefinition(
                                letter: "b",
                                meaning: "of Christ",
                                verseReferences: [
                                    VerseReference(book: "Jhn", chapter: 1, verse: 1),
                                    VerseReference(book: "Jhn", chapter: 20, verse: 28),
                                    VerseReference(book: "Rom", chapter: 9, verse: 5)
                                ]
                            ),
                            SubDefinition(
                                letter: "c",
                                meaning: "of the Holy Spirit",
                                verseReferences: [
                                    VerseReference(book: "Act", chapter: 5, verse: 3),
                                    VerseReference(book: "Act", chapter: 5, verse: 4)
                                ]
                            )
                        ]
                    )
                ],
                totalOccurrences: occurrences > 0 ? occurrences : 1343,
                source: "Abbott-Smith. A Manual Greek Lexicon of the New Testament. Sourced from Tyndale House, Cambridge."
            )

        case "G3056": // λόγος (logos) - word
            return LexiconEntry(
                strongsNumber: "G3056",
                originalText: "λόγος",
                transliteration: "logos",
                partOfSpeechLabel: "λόγος, -ου, ὁ, in LXX",
                definitions: [
                    Definition(
                        number: 1,
                        meaning: "a word, speech, divine utterance, analogy",
                        verseReferences: Array(verseRefs.prefix(4)),
                        subDefinitions: [
                            SubDefinition(
                                letter: "a",
                                meaning: "of the spoken word",
                                verseReferences: [
                                    VerseReference(book: "Mat", chapter: 12, verse: 37),
                                    VerseReference(book: "Luk", chapter: 1, verse: 4)
                                ]
                            ),
                            SubDefinition(
                                letter: "b",
                                meaning: "of the inward word, thought",
                                verseReferences: [
                                    VerseReference(book: "Mat", chapter: 15, verse: 6),
                                    VerseReference(book: "Mar", chapter: 7, verse: 13)
                                ]
                            )
                        ]
                    ),
                    Definition(
                        number: 2,
                        meaning: "the Word (Logos), title of the Son of God",
                        verseReferences: [
                            VerseReference(book: "Jhn", chapter: 1, verse: 1),
                            VerseReference(book: "Jhn", chapter: 1, verse: 14),
                            VerseReference(book: "1Jn", chapter: 1, verse: 1),
                            VerseReference(book: "Rev", chapter: 19, verse: 13)
                        ]
                    )
                ],
                totalOccurrences: occurrences > 0 ? occurrences : 330,
                source: "Abbott-Smith. A Manual Greek Lexicon of the New Testament. Sourced from Tyndale House, Cambridge."
            )

        case "G746": // ἀρχή (archē) - beginning
            return LexiconEntry(
                strongsNumber: "G746",
                originalText: "ἀρχή",
                transliteration: "archē",
                partOfSpeechLabel: "ἀρχή, -ῆς, ἡ, in LXX",
                definitions: [
                    Definition(
                        number: 1,
                        meaning: "beginning, origin",
                        verseReferences: Array(verseRefs.prefix(5)),
                        subDefinitions: [
                            SubDefinition(
                                letter: "a",
                                meaning: "of time",
                                verseReferences: [
                                    VerseReference(book: "Jhn", chapter: 1, verse: 1),
                                    VerseReference(book: "Mat", chapter: 24, verse: 8)
                                ]
                            ),
                            SubDefinition(
                                letter: "b",
                                meaning: "of origin or active cause",
                                verseReferences: [
                                    VerseReference(book: "Heb", chapter: 6, verse: 1),
                                    VerseReference(book: "Rev", chapter: 3, verse: 14)
                                ]
                            )
                        ]
                    ),
                    Definition(
                        number: 2,
                        meaning: "sovereignty, dominion, magistracy",
                        verseReferences: [
                            VerseReference(book: "Luk", chapter: 20, verse: 20),
                            VerseReference(book: "Rom", chapter: 13, verse: 3)
                        ]
                    )
                ],
                totalOccurrences: occurrences > 0 ? occurrences : 55,
                source: "Abbott-Smith. A Manual Greek Lexicon of the New Testament. Sourced from Tyndale House, Cambridge."
            )

        default:
            return nil
        }
    }

    // MARK: - Helpers

    private func abbreviateBookName(_ fullName: String) -> String {
        // Reverse lookup in BookAbbreviations
        for (abbrev, name) in BookAbbreviations.mapping {
            if name == fullName {
                return abbrev
            }
        }
        // If not found, try to create a 3-letter abbreviation
        return String(fullName.prefix(3))
    }
}
