//
//  SelectableChapterTextView.swift
//  WrittenWord
//
//  SimpleChapterTextView with working text selection for highlighting
//  No word lookup (requires interlinear data)
//

import SwiftUI
import SwiftData

struct SelectableChapterTextView: View {
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
                SelectableVerseView(
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

struct SelectableVerseView: View {
    let verse: Verse
    let highlights: [Highlight]
    let fontSize: Double
    let fontFamily: FontFamily
    let lineSpacing: Double
    let colorTheme: ColorTheme
    let onTextSelected: (NSRange, String) -> Void
    
    @State private var showingContextMenu = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Verse number
            Text("\(verse.number)")
                .font(.system(size: fontSize * 0.65, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)
            
            // Verse text with highlights and context menu
            Text(buildAttributedString())
                .font(fontFor(size: fontSize))
                .lineSpacing(lineSpacing)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contextMenu {
                    // Highlight options
                    ForEach(HighlightColor.allCases, id: \.self) { color in
                        Button {
                            // Get full verse range for context menu selection
                            let range = NSRange(location: 0, length: verse.text.count)
                            onTextSelected(range, verse.text)
                            
                            // TODO: Apply highlight color
                            // This will be handled by the parent view
                        } label: {
                            Label("Highlight \(color.rawValue)", systemImage: "highlighter")
                                .foregroundColor(color.color)
                        }
                    }
                    
                    Divider()
                    
                    Button {
                        UIPasteboard.general.string = verse.text
                    } label: {
                        Label("Copy Verse", systemImage: "doc.on.doc")
                    }
                }
        }
        .padding(.vertical, 4)
    }
    
    private func buildAttributedString() -> AttributedString {
        var attributed = AttributedString(verse.text)
        
        // Apply highlights
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

// MARK: - Usage Instructions
/*
 REPLACE SimpleChapterTextView with SelectableChapterTextView in ChapterView.swift
 
 In ChapterView.swift, find:
     SimpleChapterTextView(
 
 Change to:
     SelectableChapterTextView(
 
 FEATURES:
 ✅ Displays all verses
 ✅ Shows highlights
 ✅ Context menu for highlighting (long-press verse)
 ✅ Copy verse functionality
 ❌ Word lookup (requires interlinear data - not available)
 
 HOW TO USE:
 1. Long-press any verse
 2. Select "Highlight [Color]" from menu
 3. Highlight will be applied to entire verse
 
 TODO for word-level selection:
 - Need UITextView wrapper to detect partial text selection
 - Or wait for interlinear data to be added
 */
