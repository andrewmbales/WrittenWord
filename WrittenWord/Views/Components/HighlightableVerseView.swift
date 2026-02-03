//
//  HighlightableVerseView.swift
//  WrittenWord
//
//  Enhanced verse display with highlighting and proper line spacing support
//

import SwiftUI
import SwiftData
import UIKit

// MARK: - Main Highlightable Verse View
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
            // Verse number
            Text("\(verse.number)")
                .font(.system(size: fontSize * 0.7))
                .foregroundStyle(.secondary)
                .padding(6)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Circle())
                .frame(width: 36)
            
            // Verse text with highlights
            SelectableTextView(
                text: verse.text,
                highlights: verseHighlights,
                fontSize: fontSize,
                fontFamily: fontFamily,
                lineSpacing: lineSpacing,
                selectedRange: $selectedRange,
                onHighlight: { range, text in
                    selectedRange = range
                    selectedText = text
                    showHighlightMenu = true
                }
            )
            .foregroundColor(colorTheme.textColor)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
    }
}

// MARK: - Selectable Text View (UIKit-based for proper text selection)
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
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true

        // Enable text wrapping
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.widthTracksTextView = true

        // Set proper content priorities for wrapping
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        // Build attributed text with proper line spacing
        let attributedText = buildAttributedText()
        uiView.attributedText = attributedText

        // Force layout update to reflect line spacing changes
        uiView.invalidateIntrinsicContentSize()
        uiView.setNeedsLayout()
        uiView.layoutIfNeeded()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func buildAttributedText() -> NSAttributedString {
        let attributedText = NSMutableAttributedString(string: text)
        
        // Set base font and line spacing - THIS IS THE KEY FIX
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing  // ← Line spacing applied here
        paragraphStyle.lineBreakMode = .byWordWrapping
        
        // Get font based on family
        let baseFont: UIFont
        switch fontFamily {
        case .system:
            baseFont = UIFont.systemFont(ofSize: fontSize)
        case .serif:
            baseFont = UIFont(name: "Georgia", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
        case .monospaced:
            baseFont = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        case .rounded:
            let system = UIFont.systemFont(ofSize: fontSize, weight: .regular)
            if let roundedDescriptor = system.fontDescriptor.withDesign(.rounded) {
                baseFont = UIFont(descriptor: roundedDescriptor, size: fontSize)
            } else {
                baseFont = system
            }
        }
        
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: baseFont,
            .paragraphStyle: paragraphStyle
        ]
        
        attributedText.addAttributes(baseAttributes, range: NSRange(location: 0, length: attributedText.length))
        
        // Apply highlights
        for highlight in highlights {
            let range = NSRange(location: highlight.startIndex, length: highlight.endIndex - highlight.startIndex)
            if range.location >= 0 && range.location + range.length <= attributedText.length {
                attributedText.addAttribute(
                    .backgroundColor,
                    value: UIColor(highlight.highlightColor),
                    range: range
                )
            }
        }
        
        return attributedText
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: SelectableTextView
        
        init(_ parent: SelectableTextView) {
            self.parent = parent
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            let selectedRange = textView.selectedRange
            if selectedRange.length > 0,
               let selectedText = textView.text(in: textView.selectedTextRange!) {
                parent.selectedRange = selectedRange
                parent.onHighlight(selectedRange, selectedText)
            }
        }
    }
}

// MARK: - SwiftUI Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Verse.self,
        Highlight.self,
        configurations: config
    )
    
    let verse = Verse(number: 1, text: "In the beginning God created the heaven and the earth.")
    
    return HighlightableVerseView(
        verse: verse,
        selectedText: .constant(""),
        selectedRange: .constant(nil),
        showHighlightMenu: .constant(false)
    )
    .modelContainer(container)
}
