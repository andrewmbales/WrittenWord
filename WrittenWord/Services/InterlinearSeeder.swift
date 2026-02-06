//
//  InterlinearSeeder.swift
//  WrittenWord
//
//  Loads interlinear data from bundled JSON files (one per NT book)
//

import Foundation
import SwiftData

// MARK: - Decodable Models

struct InterlinearWordData: Decodable {
    let originalText: String
    let transliteration: String
    let strongsNumber: String
    let gloss: String
    let morphology: String
    let wordIndex: Int
    let startPosition: Int
    let endPosition: Int
    let translatedText: String
    let language: String
}

struct InterlinearVerseData: Decodable {
    let chapter: Int
    let verse: Int
    let words: [InterlinearWordData]
}

struct InterlinearBookData: Decodable {
    let book: String
    let verses: [InterlinearVerseData]
}

// MARK: - Seeding Logic

@MainActor
func seedInterlinearData(modelContext: ModelContext) async throws {
    let didSeedKey = "didSeedInterlinear"
    let didSeedInterlinear = UserDefaults.standard.bool(forKey: didSeedKey)
    
    guard !didSeedInterlinear else {
        print("✅ Interlinear data already seeded")
        return
    }
    
    print("📖 Seeding interlinear data from bundled JSON...")
    
    // DIAGNOSTIC: Check what's actually in the bundle
    print("🔍 DIAGNOSTIC: Checking bundle contents...")
    
    // Method 1: Look for subdirectory
    if let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "interlinear") {
        print("   ✅ Found \(urls.count) files in 'interlinear' subdirectory")
        for url in urls.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            print("      - \(url.lastPathComponent)")
        }
    } else {
        print("   ⚠️  No files found in 'interlinear' subdirectory")
    }
    
    // Method 2: Look for all JSON files in bundle
    if let allJsonUrls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) {
        print("   📄 All JSON files in bundle: \(allJsonUrls.count)")
        for url in allJsonUrls.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
            print("      - \(url.path)")
        }
    } else {
        print("   ⚠️  No JSON files found anywhere in bundle")
    }
    
    // Method 3: Try specific file
    if let testUrl = Bundle.main.url(forResource: "john", withExtension: "json", subdirectory: "interlinear") {
        print("   ✅ Found specific file: john.json at \(testUrl.path)")
    } else {
        print("   ⚠️  Could not find john.json in interlinear subdirectory")
    }
    
    // Method 4: Try without subdirectory
    if let testUrl = Bundle.main.url(forResource: "john", withExtension: "json") {
        print("   ✅ Found john.json without subdirectory at \(testUrl.path)")
    } else {
        print("   ⚠️  Could not find john.json anywhere")
    }
    
    // Try to find the files - first with subdirectory, then without
    var urls: [URL]?
    
    // Try with subdirectory first
    urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "interlinear")
    
    // If not found, try without subdirectory (files might be at root)
    if urls == nil || urls?.isEmpty == true {
        print("   ⚠️  Trying to find JSON files at bundle root instead...")
        
        // Get all JSON files and filter for NT books
        let allJsonUrls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil) ?? []
        
        // Filter out kjv.json and only keep NT book files
        let ntBooks = [
            "matthew", "mark", "luke", "john", "acts",
            "romans", "1_corinthians", "2_corinthians", "galatians", "ephesians",
            "philippians", "colossians", "1_thessalonians", "2_thessalonians",
            "1_timothy", "2_timothy", "titus", "philemon",
            "hebrews", "james", "1_peter", "2_peter",
            "1_john", "2_john", "3_john", "jude", "revelation"
        ]
        
        urls = allJsonUrls.filter { url in
            let filename = url.deletingPathExtension().lastPathComponent.lowercased()
            return ntBooks.contains(filename)
        }
        
        if !urls!.isEmpty {
            print("   ✅ Found \(urls!.count) NT book JSON files at bundle root")
        }
    }
    
    guard let urls = urls, !urls.isEmpty else {
        print("   ❌ No interlinear JSON files found in bundle!")
        print("   📋 Please check:")
        print("      1. Files are in Xcode project navigator")
        print("      2. Files are in 'Copy Bundle Resources' build phase")
        print("      3. Files use 'folder references' (blue folder) not 'groups' (yellow folder)")
        return
    }
    
    let sortedUrls = urls.sorted { $0.lastPathComponent < $1.lastPathComponent }
    
    print("   Found \(sortedUrls.count) interlinear JSON files")
    
    for url in sortedUrls {
        let filename = url.deletingPathExtension().lastPathComponent
        
        // Convert filename to book name (e.g., "john" -> "John", "1_john" -> "1 John")
        let bookName = filename
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
        
        print("   📝 Seeding \(bookName)...")
        
        do {
            let data = try Data(contentsOf: url)
            let bookData = try JSONDecoder().decode(InterlinearBookData.self, from: data)
            
            var wordsInserted = 0
            
            for verseData in bookData.verses {
                // Find the verse in the database
                let targetVerseNumber = verseData.verse
                let fetchDescriptor = FetchDescriptor<Verse>(
                    predicate: #Predicate<Verse> { verse in
                        verse.number == targetVerseNumber
                    }
                )

                let verses = try modelContext.fetch(fetchDescriptor)
                guard let verse = verses.first else {
                    // Verse not found - skip silently (may be from different translation)
                    continue
                }

                
                // Skip if already has interlinear data
                guard verse.words.isEmpty else { continue }
                
                // Insert words
                for wordData in verseData.words {
                    let word = Word(
                        originalText: wordData.originalText,
                        transliteration: wordData.transliteration,
                        strongsNumber: wordData.strongsNumber,
                        gloss: wordData.gloss,
                        morphology: wordData.morphology,
                        wordIndex: wordData.wordIndex,
                        startPosition: wordData.startPosition,
                        endPosition: wordData.endPosition,
                        translatedText: wordData.translatedText,
                        language: wordData.language,
                        verse: verse
                    )
                    
                    modelContext.insert(word)
                    verse.words.append(word)
                    wordsInserted += 1
                }
            }
            
            // Save per book to avoid memory pressure
            try modelContext.save()
            print("      ✅ Inserted \(wordsInserted) words")
            
        } catch {
            print("      ❌ Error processing \(filename): \(error)")
        }
    }
    
    if (didSeedInterlinear == true) {
        print("🎉 Interlinear data seeding complete!")
    }
}
