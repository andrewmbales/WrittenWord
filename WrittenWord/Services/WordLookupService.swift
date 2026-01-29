//
//  WordLookupService.swift
//  WrittenWord
//
//  Service for looking up original language words (interlinear data)
//

import Foundation
import SwiftData

class WordLookupService {
    /// Find the original language word at a specific character position in a verse
    /// - Parameters:
    ///   - verse: The verse to search in
    ///   - position: The character position in the verse text
    /// - Returns: The Word at that position, if found
    static func findWord(in verse: Verse, at position: Int) -> Word? {
        // Find the word that contains this character position
        return verse.words.first { word in
            position >= word.startPosition && position < word.endPosition
        }
    }

    /// Find the original language word for a selected range in a verse
    /// - Parameters:
    ///   - verse: The verse to search in
    ///   - range: The NSRange of selected text
    /// - Returns: The Word at the start of the range, if found
    static func findWord(in verse: Verse, for range: NSRange) -> Word? {
        return findWord(in: verse, at: range.location)
    }

    /// Get all words for a verse, sorted by word index
    /// - Parameter verse: The verse to get words for
    /// - Returns: Sorted array of words
    static func getWords(for verse: Verse) -> [Word] {
        return verse.words.sorted { $0.wordIndex < $1.wordIndex }
    }

    /// Extract a single word from text at a given position
    /// - Parameters:
    ///   - text: The full text
    ///   - position: Character position
    /// - Returns: Tuple of (word text, start position, end position)
    static func extractWord(from text: String, at position: Int) -> (word: String, start: Int, end: Int)? {
        guard position >= 0 && position < text.count else { return nil }

        // Convert to String.Index
        let index = text.index(text.startIndex, offsetBy: position)

        // Find word boundaries
        var start = index
        var end = index

        // Move start backwards to beginning of word
        while start > text.startIndex {
            let prevIndex = text.index(before: start)
            let char = text[prevIndex]
            if char.isWhitespace || char.isPunctuation {
                break
            }
            start = prevIndex
        }

        // Move end forwards to end of word
        while end < text.endIndex {
            let char = text[end]
            if char.isWhitespace || char.isPunctuation {
                break
            }
            end = text.index(after: end)
        }

        let word = String(text[start..<end])
        let startOffset = text.distance(from: text.startIndex, to: start)
        let endOffset = text.distance(from: text.startIndex, to: end)

        return (word, startOffset, endOffset)
    }
}
