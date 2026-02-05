//
//  SwiftUIChapterTextView.swift
//  WrittenWord
//
//  Pure SwiftUI approach - no UITextView, just Text with proper line spacing
//

import SwiftUI
import SwiftData

struct SwiftUIChapterTextView: View {
    let verses: [Verse]
    let highlights: [Highlight]
    let fontSize: Double
    let fontFamily: FontFamily
    let lineSpacing: Double
    let colorTheme: ColorTheme
    let onTextSelected: (Verse, NSRange, String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(verses) { verse in
                SwiftUIVerseView(
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
                .padding(.vertical, 6)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SwiftUIVerseView: View {
    let verse: Verse
    let highlights: [Highlight]
    let fontSize: Double
    let fontFamily: FontFamily
    let lineSpacing: Double
    let colorTheme: ColorTheme
    let onTextSelected: (NSRange, String) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Verse number
            Text("\(verse.number)")
                .font(.system(size: fontSize * 0.65, weight: .semibold, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .leading)
            
            // Verse text with highlights and native text selection
            Text(buildAttributedString())
                .font(fontFor(size: fontSize))
                .lineSpacing(lineSpacing)  // ✅ THIS ACTUALLY WORKS IN SWIFTUI!
                .textSelection(.enabled)   // ✅ NATIVE TEXT SELECTION
                .frame(maxWidth: .infinity, alignment: .leading)
                .contextMenu {
                    contextMenuItems
                }
        }
    }
    
    @ViewBuilder
    private var contextMenuItems: some View {
        // Quick highlight entire verse
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

// MARK: - Preview

#Preview {
    let verse1 = Verse(number: 1, text: "In the beginning God created the heaven and the earth.")
    let verse2 = Verse(number: 2, text: "And the earth was without form, and void; and darkness was upon the face of the deep. And the Spirit of God moved upon the face of the waters.")
    
    return ScrollView {
        SwiftUIChapterTextView(
            verses: [verse1, verse2],
            highlights: [],
            fontSize: 18,
            fontFamily: .system,
            lineSpacing: 12,
            colorTheme: .system,
            onTextSelected: { verse, range, text in
                print("Selected: \(text)")
            }
        )
    }
}
