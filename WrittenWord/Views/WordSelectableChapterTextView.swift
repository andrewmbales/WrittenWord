//
//  WordSelectableChapterTextView.swift - DIAGNOSTIC VERSION
//  WrittenWord
//
//  Adding comprehensive diagnostics to see what UITextView is actually rendering
//

import SwiftUI
import SwiftData
import UIKit

struct WordSelectableChapterTextView: UIViewRepresentable {
    let verses: [Verse]
    let highlights: [Highlight]
    let fontSize: Double
    let fontFamily: FontFamily
    let lineSpacing: Double  // ← This needs to trigger updates
    let colorTheme: ColorTheme
    let onTextSelected: (Verse, NSRange, String) -> Void
        
    // ✅ ADD: Explicit update trigger
    var updateTrigger: String {
        "\(fontSize)-\(lineSpacing)-\(fontFamily.rawValue)-\(colorTheme.rawValue)"
    }
        
    func makeUIView(context: Context) -> UITextView {
        print("📱 WordSelectableChapterTextView.makeUIView() called")
        print("   Initial lineSpacing: \(lineSpacing)")
        print("   Initial fontSize: \(fontSize)")
        
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

        // CRITICAL: Set content hugging and compression resistance for proper wrapping
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        // Enable font leading for consistent line height
        textView.layoutManager.usesFontLeading = true

        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        print("🔄 WordSelectableChapterTextView.updateUIView() called")
        print("   Current lineSpacing: \(lineSpacing)")
        print("   Current fontSize: \(fontSize)")
        print("   Verses count: \(verses.count)")
        
        // Update coordinator with current verses
        context.coordinator.verses = verses
        
        // Build attributed text
        let attributedText = buildAttributedText()
        
        // ✅ NUCLEAR FIX: Directly modify textStorage instead of attributedText
        textView.textStorage.setAttributedString(attributedText)
        
        // ✅ Force layout manager to invalidate ALL cached measurements
        let fullRange = NSRange(location: 0, length: textView.textStorage.length)
        textView.layoutManager.invalidateLayout(forCharacterRange: fullRange, actualCharacterRange: nil)
        textView.layoutManager.invalidateDisplay(forCharacterRange: fullRange)
        
        // Update text container configuration
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.widthTracksTextView = true
        
        // Update insets
        let verticalInset = fontSize * 0.25
        textView.textContainerInset = UIEdgeInsets(
            top: verticalInset,
            left: 20,
            bottom: verticalInset,
            right: 20
        )
        textView.textContainer.lineFragmentPadding = 0
        
        // Force synchronous layout calculation
        textView.layoutManager.ensureLayout(for: textView.textContainer)
        
        // Force complete relayout
        textView.invalidateIntrinsicContentSize()
        textView.setNeedsLayout()
        textView.layoutIfNeeded()
        
        // 🔍 DIAGNOSTIC: What is UITextView ACTUALLY rendering?
        print("   🔍 DIAGNOSTIC - Inspecting actual rendered attributes:")
        if attributedText.length > 0 {
            let range = NSRange(location: 0, length: min(100, attributedText.length))
            var effectiveRange = NSRange()
            if let paragraphStyle = attributedText.attribute(.paragraphStyle, at: 0, effectiveRange: &effectiveRange) as? NSParagraphStyle {
                print("      ✓ Stored paragraph style:")
                print("        - lineSpacing: \(paragraphStyle.lineSpacing)")
                print("        - minimumLineHeight: \(paragraphStyle.minimumLineHeight)")
                print("        - maximumLineHeight: \(paragraphStyle.maximumLineHeight)")
                print("        - lineBreakMode: \(paragraphStyle.lineBreakMode.rawValue)")
            }
            
            // Check what the textView's textStorage has
            if textView.textStorage.length > 0 {
                if let storedStyle = textView.textStorage.attribute(.paragraphStyle, at: 0, effectiveRange: &effectiveRange) as? NSParagraphStyle {
                    print("      ✓ TextStorage paragraph style:")
                    print("        - lineSpacing: \(storedStyle.lineSpacing)")
                    print("        - minimumLineHeight: \(storedStyle.minimumLineHeight)")
                    print("        - maximumLineHeight: \(storedStyle.maximumLineHeight)")
                }
            }
            
            // Check layout manager's actual line heights
            let glyphRange = textView.layoutManager.glyphRange(for: textView.textContainer)
            if glyphRange.length > 0 {
                var lineNumber = 0
                textView.layoutManager.enumerateLineFragments(forGlyphRange: NSRange(location: 0, length: min(100, glyphRange.length))) { rect, usedRect, textContainer, glyphRange, stop in
                    if lineNumber < 3 {
                        print("      ✓ Line \(lineNumber) actual rendering:")
                        print("        - rect height: \(rect.height)")
                        print("        - usedRect height: \(usedRect.height)")
                        lineNumber += 1
                    }
                }
            }
        }
        
        print("   ✅ updateUIView completed")
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func buildAttributedText() -> NSAttributedString {
        print("📝 buildAttributedText() called")
        print("   Using lineSpacing: \(lineSpacing)")
        
        let result = NSMutableAttributedString()
        
        for (index, verse) in verses.enumerated() {
            // Verse number
            let verseNumber = NSMutableAttributedString(string: "\(verse.number) ")
            verseNumber.addAttributes([
                .font: UIFont.boldSystemFont(ofSize: fontSize * 0.75),
                .foregroundColor: UIColor.secondaryLabel,
                .baselineOffset: fontSize * 0.15
            ], range: NSRange(location: 0, length: verseNumber.length))
            
            result.append(verseNumber)
            
            // Verse text
            let verseText = NSMutableAttributedString(string: verse.text)
            
            /// ✅ THE REAL FIX: lineSpacing only works BETWEEN lines, not for single-line text!
            /// Use lineHeightMultiple to control the actual line height
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
            paragraphStyle.alignment = .natural
            
            // Convert our lineSpacing slider value (2-36) to a line height multiplier
            // Base font size is 24.0, so we calculate the multiplier
            // lineSpacing 6 = tight (1.25x), 20 = comfortable (1.8x), 36 = loose (2.5x)
            let baseLineHeight = fontSize * 1.2  // Default iOS line height
            let desiredTotalLineHeight = fontSize + lineSpacing
            let lineHeightMultiplier = desiredTotalLineHeight / fontSize
            
            paragraphStyle.lineHeightMultiple = lineHeightMultiplier
            
            // Also set minimum/maximum to enforce it
            paragraphStyle.minimumLineHeight = desiredTotalLineHeight
            paragraphStyle.maximumLineHeight = desiredTotalLineHeight
            
            if index == 0 {
                print("   📐 Paragraph style for verse 1:")
                print("      lineSpacing: \(paragraphStyle.lineSpacing)")
                print("      minimumLineHeight: \(paragraphStyle.minimumLineHeight)")
                print("      maximumLineHeight: \(paragraphStyle.maximumLineHeight)")
                print("      fontSize: \(fontSize)")
            }
            
            // Font selection
            let font: UIFont
            switch fontFamily {
            case .system:
                font = UIFont.systemFont(ofSize: fontSize)
            case .serif:
                font = UIFont(name: "Georgia", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
            case .rounded:
                let descriptor = UIFont.systemFont(ofSize: fontSize).fontDescriptor
                    .withDesign(.rounded) ?? UIFont.systemFont(ofSize: fontSize).fontDescriptor
                font = UIFont(descriptor: descriptor, size: fontSize)
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
            
            // Add proper spacing between verses
            if index < verses.count - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }
        
        print("   ✅ buildAttributedText completed")
        return result
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: WordSelectableChapterTextView
        var verses: [Verse]
        private var selectionDebounceTask: Task<Void, Never>?
        
        init(_ parent: WordSelectableChapterTextView) {
            self.parent = parent
            self.verses = parent.verses
            super.init()
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
