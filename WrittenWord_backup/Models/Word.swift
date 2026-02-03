//
//  Word.swift
//  WrittenWord
//
//  Model for storing interlinear word data (Greek/Hebrew original language information)
//

import Foundation
import SwiftData

@Model
final class Word {
    /// Unique identifier for the word
    var id: UUID

    /// The original language text (Hebrew, Aramaic, or Greek)
    var originalText: String

    /// Romanized transliteration of the original text
    var transliteration: String

    /// Strong's concordance number (e.g., "H1234" for Hebrew, "G1234" for Greek)
    var strongsNumber: String?

    /// English gloss or brief definition
    var gloss: String

    /// Morphological information (part of speech, tense, case, etc.)
    var morphology: String?

    /// The position/index of this word in the verse (0-based)
    var wordIndex: Int

    /// The start position of this word in the verse text (character index)
    var startPosition: Int

    /// The end position of this word in the verse text (character index)
    var endPosition: Int

    /// The actual English word(s) from the translation that correspond to this original word
    var translatedText: String

    /// Language code: "heb" for Hebrew, "grk" for Greek, "arc" for Aramaic
    var language: String

    /// Relationship to the verse this word belongs to
    var verse: Verse?

    /// Creation timestamp
    var createdAt: Date

    init(
        originalText: String,
        transliteration: String,
        strongsNumber: String? = nil,
        gloss: String,
        morphology: String? = nil,
        wordIndex: Int,
        startPosition: Int,
        endPosition: Int,
        translatedText: String,
        language: String,
        verse: Verse? = nil
    ) {
        self.id = UUID()
        self.originalText = originalText
        self.transliteration = transliteration
        self.strongsNumber = strongsNumber
        self.gloss = gloss
        self.morphology = morphology
        self.wordIndex = wordIndex
        self.startPosition = startPosition
        self.endPosition = endPosition
        self.translatedText = translatedText
        self.language = language
        self.verse = verse
        self.createdAt = Date()
    }

    /// Formatted display of the word information
    var formattedInfo: String {
        var info = "\(originalText) (\(transliteration))"
        if let strongs = strongsNumber {
            info += " - \(strongs)"
        }
        info += "\n\(gloss)"
        if let morph = morphology {
            info += "\n\(morph)"
        }
        return info
    }
}
