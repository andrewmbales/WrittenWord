//
//  FeatureTestView.swift
//  WrittenWord
//
//  Automated testing for highlighting and word lookup
//

import SwiftUI
import SwiftData

struct FeatureTestView: View {
    @Environment(\.modelContext) private var modelContext
    let chapter: Chapter
    
    @State private var testResults: [String] = []
    @State private var showingResults = false
    
    private var sortedVerses: [Verse] {
        chapter.verses.sorted { $0.number < $1.number }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("🧪 Feature Testing")
                    .font(.largeTitle.bold())
                
                Text("\(chapter.book?.name ?? "Unknown") \(chapter.number)")
                    .font(.title2)
                    .foregroundColor(.secondary)
                
                Divider()
                
                // Test buttons
                VStack(spacing: 12) {
                    TestButton(title: "Test 1: Check Interlinear Data", color: .blue) {
                        testInterlinearData()
                    }
                    
                    TestButton(title: "Test 2: Create Manual Highlight", color: .green) {
                        testManualHighlight()
                    }
                    
                    TestButton(title: "Test 3: Query Existing Highlights", color: .orange) {
                        testQueryHighlights()
                    }
                    
                    TestButton(title: "Test 4: Check Verse Data", color: .purple) {
                        testVerseData()
                    }
                    
                    TestButton(title: "Test 5: Text Selection Mock", color: .red) {
                        testTextSelection()
                    }
                }
                
                Divider()
                
                // Results
                if !testResults.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📊 Test Results")
                            .font(.headline)
                        
                        ForEach(Array(testResults.enumerated()), id: \.offset) { index, result in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(result)
                                    .font(.caption)
                                    .foregroundColor(result.contains("✅") ? .green : result.contains("❌") ? .red : .primary)
                            }
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
                    
                    Button("Clear Results") {
                        testResults.removeAll()
                    }
                    .foregroundColor(.red)
                }
            }
            .padding()
        }
        .navigationTitle("Feature Tests")
    }
    
    // MARK: - Test Functions
    
    private func testInterlinearData() {
        addResult("🔍 Testing Interlinear Data...")
        
        guard !sortedVerses.isEmpty else {
            addResult("❌ No verses found!")
            return
        }
        
        var totalWords = 0
        for verse in sortedVerses.prefix(5) {
            let wordCount = verse.words.count
            totalWords += wordCount
            
            addResult("Verse \(verse.number): \(wordCount) words")
            
            for word in verse.words.prefix(3) {
                addResult("  → \(word.translatedText): \(word.originalText) (\(word.strongsNumber ?? "no strongs"))")
            }
        }
        
        if totalWords > 0 {
            addResult("✅ Found \(totalWords) interlinear words in first 5 verses")
        } else {
            addResult("❌ No interlinear data found - word lookup won't work")
        }
    }
    
    private func testManualHighlight() {
        addResult("🎨 Testing Manual Highlight Creation...")
        
        guard let firstVerse = sortedVerses.first else {
            addResult("❌ No verses available")
            return
        }
        
        // Create a test highlight
        let highlight = Highlight(
            verseId: firstVerse.id,
            startIndex: 0,
            endIndex: min(10, firstVerse.text.count),
            color: .yellow,
            text: String(firstVerse.text.prefix(10)),
            verse: firstVerse
        )
        
        modelContext.insert(highlight)
        
        do {
            try modelContext.save()
            addResult("✅ Highlight created and saved")
            addResult("   Verse: \(firstVerse.number)")
            addResult("   Text: '\(highlight.text)'")
            addResult("   Color: \(highlight.highlightColor)")
        } catch {
            addResult("❌ Failed to save highlight: \(error.localizedDescription)")
        }
    }
    
    private func testQueryHighlights() {
        addResult("📋 Testing Highlight Query...")
        
        let descriptor = FetchDescriptor<Highlight>()
        
        do {
            let highlights = try modelContext.fetch(descriptor)
            addResult("✅ Found \(highlights.count) total highlights")
            
            for (index, highlight) in highlights.prefix(5).enumerated() {
                addResult("   \(index + 1). '\(highlight.text)' - \(highlight.highlightColor)")
            }
            
            if highlights.isEmpty {
                addResult("❌ No highlights exist - create one first with Test 2")
            }
        } catch {
            addResult("❌ Failed to query highlights: \(error.localizedDescription)")
        }
    }
    
    private func testVerseData() {
        addResult("📖 Testing Verse Data...")
        
        addResult("Total verses: \(sortedVerses.count)")
        
        guard !sortedVerses.isEmpty else {
            addResult("❌ No verses found!")
            return
        }
        
        for verse in sortedVerses.prefix(3) {
            addResult("Verse \(verse.number):")
            addResult("  Text length: \(verse.text.count) chars")
            addResult("  Preview: \(String(verse.text.prefix(50)))...")
            addResult("  Words: \(verse.words.count)")
            addResult("  Chapter: \(verse.chapter?.number ?? -1)")
            addResult("  Book: \(verse.chapter?.book?.name ?? "unknown")")
        }
        
        addResult("✅ Verse data looks good")
    }
    
    private func testTextSelection() {
        addResult("✏️ Testing Text Selection Mock...")
        
        guard let firstVerse = sortedVerses.first else {
            addResult("❌ No verses available")
            return
        }
        
        // Simulate text selection
        let mockRange = NSRange(location: 0, length: 10)
        let mockText = String(firstVerse.text.prefix(10))
        
        addResult("Simulated selection:")
        addResult("  Verse: \(firstVerse.number)")
        addResult("  Range: \(mockRange)")
        addResult("  Text: '\(mockText)'")
        
        // Check if we can find a word at this position
        let word = WordLookupService.findWord(in: firstVerse, at: mockRange.location)
        
        if let word = word {
            addResult("✅ Word lookup found:")
            addResult("  Original: \(word.originalText)")
            addResult("  Transliteration: \(word.transliteration)")
            addResult("  Strongs: \(word.strongsNumber ?? "none")")
        } else {
            addResult("❌ Word lookup found nothing - interlinear data missing")
        }
    }
    
    private func addResult(_ result: String) {
        testResults.append(result)
        print(result)  // Also print to console
    }
}

struct TestButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(color)
                .cornerRadius(10)
        }
    }
}

// MARK: - Instructions
/*
 TO USE THIS TEST VIEW:
 
 1. In ChapterView.swift, temporarily replace the body with:
 
    var body: some View {
        FeatureTestView(chapter: chapter)
    }
 
 2. Build and run
 
 3. Navigate to any chapter (Genesis 1, John 1, etc.)
 
 4. Tap each test button in order:
    - Test 1: Checks if interlinear data exists
    - Test 2: Creates a manual highlight to verify persistence
    - Test 3: Queries all highlights to see if they're saved
    - Test 4: Checks verse data structure
    - Test 5: Simulates text selection and word lookup
 
 5. Read the results and report back what you see
 
 WHAT TO LOOK FOR:
 
 - Test 1: If "0 words" → No interlinear data, word lookup won't work
 - Test 2: If "✅ Highlight created" → Persistence works
 - Test 3: Should show the highlight from Test 2
 - Test 4: Should show verse data is complete
 - Test 5: If word lookup finds nothing → No interlinear data
 
 */
