//
//  WordLookupService.swift
//  WrittenWord
//
//  OPTIMIZED: Improved word matching with word-index-based lookup and fallback strategies
//

import Foundation
import SwiftData

class WordLookupService {
    
    /// Find a word based on selected text range using improved matching algorithm
    static func findWord(in verse: Verse, for range: NSRange) -> Word? {
        #if DEBUG
        print("🔍 WordLookupService: Finding word in verse...")
        print("   Verse text: \(verse.text)")
        print("   Range: \(range.location)-\(range.location + range.length)")
        #endif
        
        // Extract the English word at the selection position
        guard let englishWord = extractWord(from: verse.text, at: range) else {
            #if DEBUG
            print("⚠️ Could not extract word from range")
            #endif
            return nil
        }
        
        #if DEBUG
        print("   Extracted word: '\(englishWord)'")
        #endif
        
        // Get all words for this verse
        let words = verse.words.sorted { $0.wordIndex < $1.wordIndex }
        
        #if DEBUG
        print("   Total words in verse: \(words.count)")
        if !words.isEmpty {
            print("   Sample words:")
            for (i, w) in words.prefix(3).enumerated() {
                print("     [\(i)] \(w.originalText) → '\(w.translatedText)' (index: \(w.wordIndex))")
            }
        }
        #endif
        
        guard !words.isEmpty else {
            #if DEBUG
            print("⚠️ No interlinear words found for this verse")
            #endif
            return nil
        }
        
        // Strategy 1: Calculate word index from tap position
        let wordIndex = calculateWordIndex(in: verse.text, at: range.location)
        
        #if DEBUG
        print("   Calculated word index: \(wordIndex)")
        #endif
        
        // Try exact word index match first
        if let match = words.first(where: { $0.wordIndex == wordIndex }) {
            #if DEBUG
            print("✅ Match by word index: \(match.originalText)")
            #endif
            return match
        }
        
        // Strategy 2: Fuzzy match on translatedText
        let normalizedEnglish = normalize(englishWord)
        
        for word in words {
            let normalizedTranslated = normalize(word.translatedText)
            
            if normalizedTranslated == normalizedEnglish {
                #if DEBUG
                print("✅ Match by translated text: \(word.originalText)")
                #endif
                return word
            }
        }
        
        // Strategy 3: Partial match (for compound words)
        for word in words {
            let normalizedTranslated = normalize(word.translatedText)
            
            if normalizedTranslated.contains(normalizedEnglish) ||
               normalizedEnglish.contains(normalizedTranslated) {
                #if DEBUG
                print("✅ Match by partial text: \(word.originalText)")
                #endif
                return word
            }
        }
        
        // Strategy 4: Character position fallback
        if let match = findByCharacterPosition(words: words, range: range) {
            #if DEBUG
            print("✅ Match by character position: \(match.originalText)")
            #endif
            return match
        }
        
        #if DEBUG
        print("❌ No match found for '\(englishWord)'")
        #endif
        return nil
    }
    
    /// Extract the English word at a given range
    private static func extractWord(from text: String, at range: NSRange) -> String? {
        guard range.location != NSNotFound,
              range.location >= 0,
              range.location < text.count else {
            return nil
        }
        
        let nsString = text as NSString
        
        // If range has length, use it directly
        if range.length > 0 {
            let word = nsString.substring(with: range)
            return cleanWord(word)
        }
        
        // Otherwise find word boundaries around tap position
        let tapPosition = range.location
        
        var start = tapPosition
        var end = tapPosition
        
        let characterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "'"))
        
        // Find start of word
        while start > 0 {
            let char = nsString.character(at: start - 1)
            if let scalar = UnicodeScalar(char), !characterSet.contains(scalar) {
                break
            }
            start -= 1
        }
        
        // Find end of word
        while end < text.count {
            let char = nsString.character(at: end)
            if let scalar = UnicodeScalar(char), !characterSet.contains(scalar) {
                break
            }
            end += 1
        }
        
        guard start < end else { return nil }
        
        let wordRange = NSRange(location: start, length: end - start)
        let word = nsString.substring(with: wordRange)
        return cleanWord(word)
    }
    
    /// Get all words for a verse, sorted by word index
    static func getWords(for verse: Verse) -> [Word] {
        return verse.words.sorted { $0.wordIndex < $1.wordIndex }
    }
    
    /// Calculate the word index (0-based) from character position
    private static func calculateWordIndex(in text: String, at position: Int) -> Int {
        guard position >= 0, position < text.count else { return 0 }
        
        // Split text into words
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        var currentPosition = 0
        
        for (index, word) in words.enumerated() {
            // Find this word in the text starting from currentPosition
            let searchRange = NSRange(location: currentPosition, length: text.count - currentPosition)
            let range = (text as NSString).range(of: word, range: searchRange)
            
            // Check if word was found (location != NSNotFound)
            if range.location != NSNotFound {
                // Check if tap position falls within this word's range
                if position >= range.location && position < range.location + range.length {
                    return index
                }
                
                // Move past this word
                currentPosition = range.location + range.length
            }
        }
        
        // Default to last word if position is at end
        return max(0, words.count - 1)
    }
    
    /// Fallback: Find word by character position overlap
    private static func findByCharacterPosition(words: [Word], range: NSRange) -> Word? {
        // Find word whose position range overlaps with selection range
        for word in words {
            let wordStart = word.startPosition
            let wordEnd = word.endPosition
            let selectionStart = range.location
            let selectionEnd = range.location + range.length
            
            // Check for overlap
            if (wordStart <= selectionEnd && wordEnd >= selectionStart) {
                return word
            }
        }
        
        return nil
    }
    
    /// Normalize word for comparison (lowercase, remove punctuation)
    private static func normalize(_ word: String) -> String {
        return word
            .lowercased()
            .trimmingCharacters(in: .punctuationCharacters)
            .trimmingCharacters(in: .whitespaces)
    }
    
    /// Clean word by removing verse numbers and extra punctuation
    private static func cleanWord(_ word: String) -> String {
        var cleaned = word
        
        // Remove leading verse numbers (e.g., "1Word" → "Word")
        cleaned = cleaned.replacingOccurrences(of: "^\\d+\\s*", with: "", options: .regularExpression)
        
        // Remove trailing punctuation (but keep apostrophes)
        cleaned = cleaned.trimmingCharacters(in: CharacterSet.punctuationCharacters.subtracting(CharacterSet(charactersIn: "'")))
        
        return cleaned
    }
}
