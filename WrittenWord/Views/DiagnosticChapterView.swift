//
//  DiagnosticChapterView.swift
//  WrittenWord
//
//  DIAGNOSTIC: Figure out what's actually wrong
//

import SwiftUI
import SwiftData

struct DiagnosticChapterView: View {
    let chapter: Chapter
    
    private var sortedVerses: [Verse] {
        chapter.verses.sorted { $0.number < $1.number }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Diagnostic info
                Text("🔍 DIAGNOSTICS")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Text("Chapter: \(chapter.book?.name ?? "Unknown") \(chapter.number)")
                    .font(.subheadline)
                
                Text("Total verses in chapter: \(chapter.verses.count)")
                    .font(.subheadline)
                
                Text("Sorted verses: \(sortedVerses.count)")
                    .font(.subheadline)
                
                Divider()
                
                // Show first 5 verses as proof
                Text("📖 FIRST 5 VERSES:")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                ForEach(Array(sortedVerses.prefix(5))) { verse in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Verse \(verse.number)")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(verse.text)
                            .font(.body)
                            .padding(.leading, 8)
                    }
                    .padding(.vertical, 4)
                }
                
                Divider()
                
                // Show ALL verses (simple)
                Text("📚 ALL VERSES:")
                    .font(.headline)
                    .foregroundColor(.green)
                
                ForEach(sortedVerses) { verse in
                    HStack(alignment: .top, spacing: 8) {
                        Text("\(verse.number)")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .frame(width: 30)
                        
                        Text(verse.text)
                            .font(.body)
                    }
                    .padding(.vertical, 2)
                }
            }
            .padding(20)
        }
        .navigationTitle("Diagnostic View")
    }
}

// MARK: - Instructions for use
/*
 TO USE THIS DIAGNOSTIC VIEW:
 
 1. In ChapterView.swift, replace the entire body with:
 
    var body: some View {
        DiagnosticChapterView(chapter: chapter)
    }
 
 2. Build and run
 
 3. Navigate to Genesis 2
 
 4. You should see:
    - Diagnostic info at the top (how many verses)
    - First 5 verses displayed
    - ALL verses displayed below
 
 WHAT THIS TELLS US:
 
 - If you see the verse count but NO verses → Data isn't loading
 - If you see "0 verses" → Chapter data is empty
 - If you see all verses → The data is fine, just the display component is broken
 - If you see nothing at all → Navigation isn't working
 
 */
