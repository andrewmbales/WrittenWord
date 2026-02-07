//
//  WordLookupService_WordIndex.swift
//  WrittenWord
//
//  Updated word lookup using word index instead of character positions
//

import Foundation
import SwiftData

class WordLookupService {
    
    /// Find a word based on selected text range
    /// Now uses word-index matching instead of character positions
    static func findWord(in verse: Verse, for range: NSRange) -> Word? {
        // Get the word at the selection position
        guard let englishWord = extractWord(from: verse.text, at: range) else {
            return nil
        }
        
        // Find matching interlinear word
        return findMatchingWord(
            englishWord: englishWord,
            inVerse: verse,
            atRange: range
        )
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
            return nsString.substring(with: range)
        }
        
        // Otherwise find word boundaries around tap position
        let tapPosition = range.location
        
        // Find word boundaries
        var start = tapPosition
        var end = tapPosition
        
        let characterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "'"))
        
        // Find start of word
        while start > 0 {
            let char = nsString.character(at: start - 1)
            if !characterSet.contains(UnicodeScalar(char)!) {
                break
            }
            start -= 1
        }
        
        // Find end of word
        while end < text.count {
            let char = nsString.character(at: end)
            if !characterSet.contains(UnicodeScalar(char)!) {
                break
            }
            end += 1
        }
        
        guard start < end else { return nil }
        
        let wordRange = NSRange(location: start, length: end - start)
        return nsString.substring(with: wordRange)
    }
    
    /// Find the interlinear word that matches the selected English word
    private static func findMatchingWord(
        englishWord: String,
        inVerse verse: Verse,
        atRange range: NSRange
    ) -> Word? {
        
        // Get all words for this verse from the database
        let words = getWordsForVerse(verse)
        
        guard !words.isEmpty else {
            print("⚠️ No interlinear words found for \(verse.chapter?.book?.name ?? "") \(verse.chapter?.number ?? 0):\(verse.number)")
            return nil
        }
        
        // Calculate which English word index this selection corresponds to
        let wordIndex = calculateWordIndex(in: verse.text, at: range.location)
        
        // Try to find by word index first (most reliable)
        if let word = findByWordIndex(words: words, wordIndex: wordIndex, englishWord: englishWord) {
            return word
        }
        
        // Fallback: try to find by matching translatedText
        if let word = findByTranslatedText(words: words, englishWord: englishWord) {
            return word
        }
        
        print("⚠️ Could not find interlinear word for '\(englishWord)' at index \(wordIndex)")
        return nil
    }
    
    /// Calculate which word (by index) was selected
    private static func calculateWordIndex(in text: String, at position: Int) -> Int {
        let beforePosition = String(text.prefix(position))
        let words = beforePosition.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        return words.count
    }
    
    /// Find word by matching word index
    private static func findByWordIndex(
        words: [Word],
        wordIndex: Int,
        englishWord: String
    ) -> Word? {
        
        // Create a mapping of English word positions
        // Some Greek words map to multiple English words, so we need to handle that
        
        var englishWordCount = 0
        
        for word in words.sorted(by: { $0.wordIndex < $1.wordIndex }) {
            let translatedText = word.translatedText.lowercased()
            
            // Count how many English words this Greek word translates to
            let englishWords = translatedText.components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty }
            
            // Check if our target index falls within this word's range
            let startIndex = englishWordCount
            let endIndex = englishWordCount + englishWords.count
            
            if wordIndex >= startIndex && wordIndex < endIndex {
                // Found it! Double-check the text matches
                let targetWord = englishWords[wordIndex - startIndex]
                if targetWord.lowercased().contains(englishWord.lowercased()) ||
                   englishWord.lowercased().contains(targetWord.lowercased()) {
                    return word
                }
            }
            
            englishWordCount += englishWords.count
        }
        
        return nil
    }
    
    /// Find word by matching translated text (fallback)
    private static func findByTranslatedText(
        words: [Word],
        englishWord: String
    ) -> Word? {
        
        let normalized = englishWord.lowercased()
            .trimmingCharacters(in: .punctuationCharacters)
        
        // Try exact match first
        if let word = words.first(where: {
            let translated = $0.translatedText.lowercased()
                .trimmingCharacters(in: .punctuationCharacters)
            return translated == normalized
        }) {
            return word
        }
        
        // Try partial match (for words like "the/this/who")
        if let word = words.first(where: {
            let alternatives = $0.translatedText.lowercased()
                .components(separatedBy: "/")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            return alternatives.contains(normalized)
        }) {
            return word
        }
        
        // Try contains (very fuzzy)
        if let word = words.first(where: {
            $0.translatedText.lowercased().contains(normalized) ||
            normalized.contains($0.translatedText.lowercased())
        }) {
            return word
        }
        
        return nil
    }
    
    /// Get all Word objects for a verse from the database
    static func getWords(for verse: Verse) -> [Word] {
        return getWordsForVerse(verse)
    }
    
    /// Get all Word objects for a verse from the database (internal implementation)
    private static func getWordsForVerse(_ verse: Verse) -> [Word] {
        guard let modelContext = verse.modelContext else {
            print("⚠️ No model context for verse")
            return []
        }
        
        // Fetch all words for this verse
        let verseId = verse.id
        let descriptor = FetchDescriptor<Word>(
            predicate: #Predicate { word in
                word.verse?.id == verseId
            },
            sortBy: [SortDescriptor(\.wordIndex, order: .forward)]
        )
        
        do {
            let words = try modelContext.fetch(descriptor)
            return words
        } catch {
            print("❌ Error fetching words: \(error)")
            return []
        }
    }
}
