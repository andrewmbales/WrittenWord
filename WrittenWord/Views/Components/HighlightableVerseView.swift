//
//  HighlightableVerseView.swift
//  WrittenWord
//
//  Phase 1: Enhanced verse display with highlighting
//
import SwiftUI
import SwiftData

struct HighlightableVerseView: View {
    let verse: Verse
    @Binding var selectedText: String
    @Binding var selectedRange: NSRange?
    @Binding var showHighlightMenu: Bool
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allHighlights: [Highlight]
    @AppStorage("fontSize") private var fontSize: Double = 16.0
    @AppStorage("lineSpacing") private var lineSpacing: Double = 6.0
    @AppStorage("fontFamily") private var fontFamily: FontFamily = .system
    @AppStorage("colorTheme") private var colorTheme: ColorTheme = .system
    
    var verseHighlights: [Highlight] {
        allHighlights.filter { $0.verseId == verse.id }
            .sorted { $0.startIndex < $1.startIndex }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Verse number - simplified without circle
            Text("\(verse.number)")
                .font(.system(size: fontSize * 0.7))
                .foregroundStyle(.secondary)
                .frame(width: 20, alignment: .leading)
            
            // Verse text with highlights
            HighlightedText(
                text: verse.text,
                highlights: verseHighlights,
                fontSize: fontSize,
                fontFamily: fontFamily,
                lineSpacing: lineSpacing,
                onTextSelected: { range, text in
                    selectedRange = range
                    selectedText = text
                    showHighlightMenu = true
                }
            )
            .textSelection(.enabled)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
    }
}

struct HighlightedText: View {
    let text: String
    let highlights: [Highlight]
    let fontSize: Double
    let fontFamily: FontFamily
    let lineSpacing: Double
    let onTextSelected: (NSRange, String) -> Void
    
    @State private var showingSelectionMenu = false
    
    var attributedString: AttributedString {
        var attributed = AttributedString(text)
        attributed.font = fontFamily.font(size: fontSize)
        
        // Apply highlights
        for highlight in highlights {
            // Convert Int indices to String indices
            let stringStartIndex = text.index(text.startIndex, offsetBy: highlight.startIndex)
            let stringEndIndex = text.index(text.startIndex, offsetBy: min(highlight.endIndex, text.count))
            
            // Convert String range to AttributedString range
            if let attrRange = Range<AttributedString.Index>(stringStartIndex..<stringEndIndex, in: attributed) {
                attributed[attrRange].backgroundColor = highlight.highlightColor
            }
        }
        
        return attributed
    }
    
    var body: some View {
        Text(attributedString)
            .lineSpacing(lineSpacing)
            .lineLimit(nil) // Allow unlimited lines for wrapping
            .multilineTextAlignment(.leading)
            .contextMenu {
                Button {
                    // Handle text selection for highlighting
                    // This is a simplified version - actual implementation would need UITextView
                } label: {
                    Label("Highlight", systemImage: "highlighter")
                }
            }
    }
}

// MARK: - UIKit-based highlightable text view for better text selection
struct SelectableTextView: UIViewRepresentable {
    let text: String
    let highlights: [Highlight]
    let fontSize: Double
    let fontFamily: FontFamily
    let lineSpacing: Double
    @Binding var selectedRange: NSRange?
    let onHighlight: (NSRange, String) -> Void
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainer.widthTracksTextView = true
        textView.textContainer.heightTracksTextView = false
        textView.setContentHuggingPriority(.defaultHigh, for: .vertical)
        textView.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        let attributedText = NSMutableAttributedString(string: text)
        
        // Set base font and spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize),
            .paragraphStyle: paragraphStyle
        ]
        
        attributedText.addAttributes(baseAttributes, range: NSRange(location: 0, length: attributedText.length))
        
        // Apply highlights
        for highlight in highlights {
            let range = NSRange(location: highlight.startIndex, length: highlight.endIndex - highlight.startIndex)
            if range.location + range.length <= attributedText.length {
                attributedText.addAttribute(.backgroundColor, 
                                          value: UIColor(highlight.highlightColor), 
                                          range: range)
            }
        }
        
        uiView.attributedText = attributedText
        
        // Force layout to calculate proper size
        uiView.setNeedsLayout()
        uiView.layoutIfNeeded()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: SelectableTextView
        
        init(_ parent: SelectableTextView) {
            self.parent = parent
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            let selectedRange = textView.selectedRange
            if selectedRange.length > 0 {
                parent.selectedRange = selectedRange
                if let selectedText = textView.text(in: textView.selectedTextRange!) {
                    parent.onHighlight(selectedRange, selectedText)
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Verse.self,
        Highlight.self,
        configurations: config
    )

    let verse = Verse(number: 1, text: "In the beginning God created the heaven and the earth.")
    container.mainContext.insert(verse)

    let highlight = Highlight(
        verseId: verse.id,
        startIndex: 17,
        endIndex: 20,
        color: .yellow,
        text: "God",
        verse: verse
    )
    container.mainContext.insert(highlight)

    HighlightableVerseView(
        verse: verse,
        selectedText: .constant(""),
        selectedRange: .constant(nil),
        showHighlightMenu: .constant(false)
    )
    .modelContainer(container)
    .padding()
}