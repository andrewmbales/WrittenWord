//
//  SimpleChapterTextView.swift
//  WrittenWord
//
//  SIMPLE APPROACH: Just display the damn text
//  No fancy UITextView tricks - use SwiftUI VStack
//

import SwiftUI
import SwiftData

struct SimpleChapterTextView: View {
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
                SimpleVerseView(
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

struct SimpleVerseView: View {
    let verse: Verse
    let highlights: [Highlight]
    let fontSize: Double
    let fontFamily: FontFamily
    let lineSpacing: Double
    let colorTheme: ColorTheme
    let onTextSelected: (NSRange, String) -> Void
    
    @State private var selectedRange: NSRange?
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Verse number
            Text("\(verse.number)")
                .font(.system(size: fontSize * 0.65, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)
            
            // Verse text with highlights
            Text(buildAttributedString())
                .font(fontFor(size: fontSize))
                .lineSpacing(lineSpacing)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
    
    private func buildAttributedString() -> AttributedString {
        var attributed = AttributedString(verse.text)
        
        // Apply highlights
        for highlight in highlights {
            let startIndex = verse.text.index(verse.text.startIndex, offsetBy: highlight.startIndex)
            let endIndex = verse.text.index(verse.text.startIndex, offsetBy: min(highlight.endIndex, verse.text.count))
            
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
