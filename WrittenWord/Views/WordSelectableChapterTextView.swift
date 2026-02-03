//
//  WordSelectableChapterTextView.swift - FIXED
//  WrittenWord
//
//  Fixed height calculation to show all text properly
//

import SwiftUI
import SwiftData
import UIKit

struct WordSelectableChapterTextView: UIViewRepresentable {
    let verses: [Verse]
    let highlights: [Highlight]
    let fontSize: Double
    let fontFamily: FontFamily
    let lineSpacing: Double
    let colorTheme: ColorTheme
    let onTextSelected: (Verse, NSRange, String) -> Void
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isEditable = false
        textView.isScrollEnabled = false  // CRITICAL - let parent ScrollView handle scrolling
        textView.backgroundColor = .clear
        
        // Proper insets for readability
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        textView.textContainer.lineFragmentPadding = 0
        
        // Enable proper text wrapping - CRITICAL for multi-line display
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.widthTracksTextView = true
        
        // Enable text selection
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true
        
        // Customize selection appearance
        textView.tintColor = UIColor.systemBlue
        
        // CRITICAL: Set content hugging and compression resistance
        textView.setContentHuggingPriority(.defaultLow, for: .vertical)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        
        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        // Update coordinator with current verses
        context.coordinator.verses = verses
        
        // Build attributed string
        let attributedText = buildAttributedText()
        textView.attributedText = attributedText
        
        // Force proper layout - CRITICAL
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.maximumNumberOfLines = 0
        
        // Ensure proper sizing
        textView.sizeToFit()
        textView.setNeedsLayout()
        textView.layoutIfNeeded()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Sizing Hint
    // This tells SwiftUI how big the view wants to be
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        guard let width = proposal.width else { return nil }
        
        // Calculate the height needed for all content
        let size = CGSize(width: width, height: .infinity)
        let boundingRect = uiView.attributedText.boundingRect(
            with: size,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        
        return CGSize(
            width: width,
            height: ceil(boundingRect.height) + 40  // Add padding
        )
    }
    
    private func buildAttributedText() -> NSAttributedString {
        let result = NSMutableAttributedString()
        
        for (index, verse) in verses.enumerated() {
            // Verse number
            let verseNumber = NSMutableAttributedString(string: "\(verse.number) ")
            verseNumber.addAttributes([
                .font: UIFont.boldSystemFont(ofSize: fontSize * 0.75),
                .foregroundColor: UIColor.secondaryLabel
            ], range: NSRange(location: 0, length: verseNumber.length))
            
            result.append(verseNumber)
            
            // Verse text
            let verseText = NSMutableAttributedString(string: verse.text)
            
            // Paragraph style for line spacing
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = lineSpacing
            paragraphStyle.lineBreakMode = .byWordWrapping
            
            // Font selection
            let font: UIFont
            switch fontFamily {
            case .system:
                font = UIFont.systemFont(ofSize: fontSize)
            case .serif:
                font = UIFont(name: "NewYorkSerif", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
            case .rounded:
                font = UIFont.systemFont(ofSize: fontSize, weight: .regular)
            case .monospaced:
                font = UIFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
            }
            
            verseText.addAttributes([
                .font: font,
                .paragraphStyle: paragraphStyle,
                .foregroundColor: colorTheme.textColor.uiColor
            ], range: NSRange(location: 0, length: verseText.length))
            
            // Apply highlights for this verse
            let verseHighlights = highlights.filter { $0.verseId == verse.id }
            for highlight in verseHighlights {
                let highlightRange = NSRange(
                    location: highlight.startIndex,
                    length: highlight.endIndex - highlight.startIndex
                )
                
                if highlightRange.location >= 0 &&
                   highlightRange.location + highlightRange.length <= verseText.length {
                    verseText.addAttribute(
                        .backgroundColor,
                        value: UIColor(highlight.highlightColor),
                        range: highlightRange
                    )
                }
            }
            
            result.append(verseText)
            
            // Add newline between verses
            if index < verses.count - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }
        
        return result
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: WordSelectableChapterTextView
        var verses: [Verse]
        private var selectionDebounceTask: Task<Void, Never>?
        
        init(_ parent: WordSelectableChapterTextView) {
            self.parent = parent
            self.verses = parent.verses
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            let selectedRange = textView.selectedRange
            
            guard selectedRange.length > 0,
                  let selectedText = textView.text(in: textView.selectedTextRange!) else {
                return
            }
            
            // Find which verse this selection belongs to
            if let verse = findVerse(at: selectedRange.location, in: textView.attributedText) {
                // Convert absolute position to verse-relative position
                let verseRange = findVerseRange(verse: verse, in: textView.attributedText)
                let relativeRange = NSRange(
                    location: selectedRange.location - verseRange.location,
                    length: selectedRange.length
                )
                
                // Debounce to allow multi-word selection
                selectionDebounceTask?.cancel()
                selectionDebounceTask = Task { @MainActor in
                    do {
                        try await Task.sleep(nanoseconds: 300_000_000) // 300ms
                        if !Task.isCancelled {
                            parent.onTextSelected(verse, relativeRange, selectedText)
                        }
                    } catch {
                        // Task cancelled
                    }
                }
            }
        }
        
        private func findVerse(at position: Int, in attributedText: NSAttributedString) -> Verse? {
            var currentPos = 0
            
            for verse in verses {
                let verseNumberLength = "\(verse.number) ".count
                let verseTextLength = verse.text.count
                let totalLength = verseNumberLength + verseTextLength + 1  // +1 for newline
                
                if position >= currentPos && position < currentPos + totalLength {
                    return verse
                }
                
                currentPos += totalLength
            }
            
            return verses.last
        }
        
        private func findVerseRange(verse: Verse, in attributedText: NSAttributedString) -> NSRange {
            var currentPos = 0
            
            for v in verses {
                let verseNumberLength = "\(v.number) ".count
                
                if v.id == verse.id {
                    return NSRange(
                        location: currentPos + verseNumberLength,
                        length: v.text.count
                    )
                }
                
                let verseTextLength = v.text.count
                currentPos += verseNumberLength + verseTextLength + 1  // +1 for newline
            }
            
            return NSRange(location: 0, length: 0)
        }
    }
}

// MARK: - Helper Extensions

extension UIFont {
    func withTraits(_ traits: UIFontDescriptor.SymbolicTraits, size: CGFloat, design: UIFontDescriptor.SystemDesign) -> UIFont {
        guard let descriptor = fontDescriptor.withDesign(design)?.withSymbolicTraits(traits) else {
            return self
        }
        return UIFont(descriptor: descriptor, size: size)
    }
}

extension Color {
    var uiColor: UIColor {
        UIColor(self)
    }
}
