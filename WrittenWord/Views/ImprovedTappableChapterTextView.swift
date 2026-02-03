//
//  ImprovedTappableChapterTextView.swift
//  WrittenWord
//
//  FIXED: Better word selection logic
//  - Can select single words
//  - Can select word ranges
//  - Clear visual feedback
//

import SwiftUI
import SwiftData

struct ImprovedTappableChapterTextView: View {
    let verses: [Verse]
    let highlights: [Highlight]
    let fontSize: Double
    let fontFamily: FontFamily
    let lineSpacing: Double
    let colorTheme: ColorTheme
    let onTextSelected: (Verse, NSRange, String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(verses) { verse in
                ImprovedTappableVerseView(
                    verse: verse,
                    highlights: highlights.filter { $0.verseId == verse.id },
                    fontSize: fontSize,
                    fontFamily: fontFamily,
                    lineSpacing: lineSpacing,
                    colorTheme: colorTheme,
                    onTextSelected: { range, text in
                        onTextSelected(verse, range, text)
                    }
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ImprovedTappableVerseView: View {
    let verse: Verse
    let highlights: [Highlight]
    let fontSize: Double
    let fontFamily: FontFamily
    let lineSpacing: Double
    let colorTheme: ColorTheme
    let onTextSelected: (NSRange, String) -> Void
    
    @State private var showingMenu = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Verse number
            Text("\(verse.number)")
                .font(.system(size: fontSize * 0.65, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)
            
            // Verse text with tap and long-press
            Text(buildAttributedString())
                .font(fontFor(size: fontSize))
                .lineSpacing(lineSpacing)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture {
                    showingMenu = true
                }
                .onLongPressGesture {
                    showingMenu = true
                }
                .contextMenu {
                    contextMenuItems
                }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingMenu) {
            ImprovedWordSelectionSheet(
                verse: verse,
                onTextSelected: onTextSelected
            )
        }
    }
    
    @ViewBuilder
    private var contextMenuItems: some View {
        // Quick highlight options
        ForEach(HighlightColor.allCases, id: \.self) { color in
            Button {
                let range = NSRange(location: 0, length: verse.text.count)
                onTextSelected(range, verse.text)
            } label: {
                Label("Highlight \(color.rawValue)", systemImage: "highlighter")
            }
        }
        
        Divider()
        
        Button {
            UIPasteboard.general.string = verse.text
        } label: {
            Label("Copy Verse", systemImage: "doc.on.doc")
        }
    }
    
    private func buildAttributedString() -> AttributedString {
        var attributed = AttributedString(verse.text)
        
        for highlight in highlights {
            guard highlight.startIndex >= 0 && highlight.endIndex <= verse.text.count else {
                continue
            }
            
            let startIndex = verse.text.index(verse.text.startIndex, offsetBy: highlight.startIndex)
            let endIndex = verse.text.index(verse.text.startIndex, offsetBy: highlight.endIndex)
            
            if let range = Range(startIndex..<endIndex, in: attributed) {
                attributed[range].backgroundColor = highlight.highlightColor
            }
        }
        
        return attributed
    }
    
    private func fontFor(size: Double) -> Font {
        switch fontFamily {
        case .system:
            return .system(size: size)
        case .serif:
            return .system(size: size, design: .serif)
        case .monospaced:
            return .system(size: size, design: .monospaced)
        case .rounded:
            return .system(size: size, design: .rounded)
        }
    }
}

// MARK: - Improved Word Selection Sheet

struct ImprovedWordSelectionSheet: View {
    let verse: Verse
    let onTextSelected: (NSRange, String) -> Void
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedWordIndices: Set<Int> = []
    
    var words: [(word: String, index: Int)] {
        var result: [(String, Int)] = []
        let components = verse.text.components(separatedBy: .whitespaces)
        for (idx, word) in components.enumerated() {
            let cleaned = word.trimmingCharacters(in: .punctuationCharacters)
            if !cleaned.isEmpty {
                result.append((cleaned, idx))
            }
        }
        return result
    }
    
    var selectedText: String {
        guard !selectedWordIndices.isEmpty else { return "" }
        let sortedIndices = selectedWordIndices.sorted()
        return sortedIndices.map { words[$0].word }.joined(separator: " ")
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Instructions
                VStack(spacing: 8) {
                    Text("Tap to Select Words")
                        .font(.headline)
                    
                    if !selectedWordIndices.isEmpty {
                        Text("Selected: \(selectedText)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                    }
                }
                .padding()
                
                // Word buttons
                ScrollView {
                    FlowLayout(spacing: 8) {
                        ForEach(Array(words.enumerated()), id: \.offset) { index, wordData in
                            ImprovedWordButton(
                                word: wordData.word,
                                isSelected: selectedWordIndices.contains(index)
                            ) {
                                toggleWord(at: index)
                            }
                        }
                    }
                    .padding()
                }
                
                // Action buttons
                HStack(spacing: 16) {
                    Button("Clear") {
                        selectedWordIndices.removeAll()
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedWordIndices.isEmpty)
                    
                    Spacer()
                    
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Done") {
                        submitSelection()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedWordIndices.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Select Text")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }
    
    private func toggleWord(at index: Int) {
        if selectedWordIndices.contains(index) {
            // Deselect
            selectedWordIndices.remove(index)
        } else {
            // Select - add to set
            selectedWordIndices.insert(index)
        }
    }
    
    private func submitSelection() {
        guard !selectedWordIndices.isEmpty else { return }
        
        let sortedIndices = selectedWordIndices.sorted()
        let selectedWords = sortedIndices.map { words[$0].word }
        let text = selectedWords.joined(separator: " ")
        
        // Calculate the range in the original verse text
        let range = calculateRange(for: sortedIndices)
        
        onTextSelected(range, text)
        dismiss()
    }
    
    private func calculateRange(for indices: [Int]) -> NSRange {
        guard !indices.isEmpty else {
            return NSRange(location: 0, length: 0)
        }

        // Build the actual character positions for each word
        let components = verse.text.components(separatedBy: .whitespaces)
        var currentPosition = 0
        var wordPositions: [(range: Range<String.Index>, cleanedWord: String)] = []

        for component in components {
            // Find the actual position in the original string
            let searchStart = verse.text.index(verse.text.startIndex, offsetBy: currentPosition)
            guard let componentRange = verse.text.range(of: component, range: searchStart..<verse.text.endIndex) else {
                continue
            }

            let cleaned = component.trimmingCharacters(in: .punctuationCharacters)
            if !cleaned.isEmpty {
                wordPositions.append((range: componentRange, cleanedWord: cleaned))
            }

            currentPosition = verse.text.distance(from: verse.text.startIndex, to: componentRange.upperBound)
        }

        let firstIndex = indices.first!
        let lastIndex = indices.last!

        guard firstIndex < wordPositions.count && lastIndex < wordPositions.count else {
            return NSRange(location: 0, length: verse.text.count)
        }

        let firstWordRange = wordPositions[firstIndex].range
        let lastWordRange = wordPositions[lastIndex].range

        let startOffset = verse.text.distance(from: verse.text.startIndex, to: firstWordRange.lowerBound)
        let endOffset = verse.text.distance(from: verse.text.startIndex, to: lastWordRange.upperBound)

        return NSRange(location: startOffset, length: endOffset - startOffset)
    }
}

struct ImprovedWordButton: View {
    let word: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(word)
                .font(.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Usage Instructions
/*
 REPLACE TappableChapterTextView with ImprovedTappableChapterTextView
 
 In ChapterView.swift, change:
     TappableChapterTextView(
 
 To:
     ImprovedTappableChapterTextView(
 
 FIXES:
 ✅ Can select single words
 ✅ Can select multiple words (tap each one)
 ✅ Can deselect words (tap again)
 ✅ Clear button to reset selection
 ✅ Better visual feedback
 ✅ Shows selected text preview
 
 HOW TO USE:
 1. Tap any verse
 2. Sheet opens with words as buttons
 3. Tap words to select them:
    - Tap one word = selects that word
    - Tap another word = adds to selection
    - Tap selected word = deselects it
 4. Press "Clear" to reset
 5. Press "Done" when ready
 6. Word lookup or highlight menu appears
 
 This uses a Set for selection, so you can:
 - Select any combination of words
 - Select non-contiguous words
 - Toggle selection easily
 */
