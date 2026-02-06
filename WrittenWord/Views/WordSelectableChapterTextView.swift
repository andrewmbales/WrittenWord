//
//  WordSelectableChapterTextView.swift
//  WrittenWord
//
//  UITextView wrapper with word selection, highlighting, and proper line spacing
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
        
    // Explicit update trigger
    var updateTrigger: String {
        "\(fontSize)-\(lineSpacing)-\(fontFamily.rawValue)-\(colorTheme.rawValue)"
    }
        
    func makeUIView(context: Context) -> UITextView {
        debugLog("rendering", "📱 Creating UITextView with lineSpacing=\(lineSpacing), fontSize=\(fontSize)")
        
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isEditable = false
        textView.isScrollEnabled = false  // Let parent ScrollView handle scrolling
        textView.backgroundColor = .clear
        
        // Proper insets for readability
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        textView.textContainer.lineFragmentPadding = 0
        
        // Enable proper text wrapping
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.widthTracksTextView = true
        
        // Enable text selection
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true
        
        // Customize selection appearance
        textView.tintColor = UIColor.systemBlue

        // Set content priorities for proper wrapping
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        // Enable font leading for consistent line height
        textView.layoutManager.usesFontLeading = true

        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        debugLog("rendering", "🔄 Updating UITextView: lineSpacing=\(lineSpacing), verses=\(verses.count)")
        
        // Update coordinator with current verses
        context.coordinator.verses = verses
        
        // Build and set attributed text
        let attributedText = buildAttributedText()
        textView.attributedText = attributedText
        
        // Force layout update
        textView.setNeedsLayout()
        textView.layoutIfNeeded()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func buildAttributedText() -> NSAttributedString {
        debugLog("rendering", "📝 Building attributed text with lineSpacing=\(lineSpacing)")
        
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
            
            // Verse text with paragraph style
            let verseText = NSMutableAttributedString(string: verse.text)
            
            // Configure paragraph style for line spacing
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineBreakMode = .byWordWrapping
            paragraphStyle.alignment = .natural
            
            // Convert lineSpacing slider value (2-36) to line height multiplier
            let desiredTotalLineHeight = fontSize + lineSpacing
            let lineHeightMultiplier = desiredTotalLineHeight / fontSize
            
            paragraphStyle.lineHeightMultiple = lineHeightMultiplier
            paragraphStyle.minimumLineHeight = desiredTotalLineHeight
            paragraphStyle.maximumLineHeight = desiredTotalLineHeight
            
            if index == 0 {
                debugLog("rendering", "📐 First verse paragraph style: min/max=\(desiredTotalLineHeight), multiplier=\(lineHeightMultiplier)")
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
                .foregroundColor: UIColor(colorTheme.textColor)  // ✅ Wrap in UIColor()
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
                        value: UIColor(highlight.highlightColor),  // ✅ Also wrap this
                        range: highlightRange
                    )
                }
            }
            
            result.append(verseText)
            
            // Add spacing between verses
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
            super.init()
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            let selectedRange = textView.selectedRange
            
            guard selectedRange.length > 0,
                  let selectedText = textView.text(in: textView.selectedTextRange!) else {
                return
            }
            
            debugLog("interaction", "📌 Text selected: range=\(selectedRange), length=\(selectedRange.length)")
            
            // Cancel previous debounce
            selectionDebounceTask?.cancel()
            
            // Debounce selection to avoid excessive callbacks
            selectionDebounceTask = Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled else { return }
                
                // Find which verse this selection belongs to
                if let verse = self.findVerseForRange(selectedRange, in: textView) {
                    debugLog("interaction", "📍 Selection in verse \(verse.number)")
                    
                    // Calculate verse-relative range
                    if let relativeRange = self.calculateVerseRelativeRange(
                        selectedRange,
                        for: verse,
                        in: textView
                    ) {
                        self.parent.onTextSelected(verse, relativeRange, selectedText)
                    }
                }
            }
        }
        
        private func findVerseForRange(_ range: NSRange, in textView: UITextView) -> Verse? {
            //let text = textView.attributedText.string
            var currentPosition = 0
            
            for verse in verses {
                let verseNumberLength = "\(verse.number) ".count
                let verseTextLength = verse.text.count
                let totalLength = verseNumberLength + verseTextLength + 1 // +1 for newline
                
                let verseRange = NSRange(location: currentPosition, length: totalLength)
                
                if NSIntersectionRange(range, verseRange).length > 0 {
                    return verse
                }
                
                currentPosition += totalLength
            }
            
            return nil
        }
        
        private func calculateVerseRelativeRange(_ range: NSRange, for verse: Verse, in textView: UITextView) -> NSRange? {
            //let text = textView.attributedText.string
            var currentPosition = 0
            
            for v in verses {
                let verseNumberLength = "\(v.number) ".count
                
                if v.id == verse.id {
                    // Adjust range to be relative to verse text (skip verse number)
                    let verseStart = currentPosition + verseNumberLength
                    let relativeStart = range.location - verseStart
                    
                    // Ensure range is within verse bounds
                    guard relativeStart >= 0, relativeStart + range.length <= verse.text.count else {
                        return nil
                    }
                    
                    return NSRange(location: relativeStart, length: range.length)
                }
                
                currentPosition += verseNumberLength + v.text.count + 1
            }
            
            return nil
        }
    }
}
