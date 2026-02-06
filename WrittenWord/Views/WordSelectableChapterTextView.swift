//
//  WordSelectableChapterTextView.swift
//  WrittenWord
//
//  UITextView wrapper with word selection, highlighting, proper line spacing,
//  and optional verse borders for debugging (using underline for visibility)
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
    
    // Debug option to show verse borders
    @AppStorage("showVerseBorders") private var showVerseBorders: Bool = false
        
    // Explicit update trigger
    var updateTrigger: String {
        "\(fontSize)-\(lineSpacing)-\(fontFamily.rawValue)-\(colorTheme.rawValue)-\(showVerseBorders)"
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
        debugLog("rendering", "🔄 Updating UITextView: lineSpacing=\(lineSpacing), verses=\(verses.count), verseBorders=\(showVerseBorders)")
        
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
        debugLog("rendering", "📝 Building attributed text with lineSpacing=\(lineSpacing), verseBorders=\(showVerseBorders)")
        
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
            
            // Add padding between verses when borders are shown
            if showVerseBorders {
                paragraphStyle.paragraphSpacing = 12
                paragraphStyle.paragraphSpacingBefore = 12
            }
            
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
                .foregroundColor: UIColor(colorTheme.textColor)
            ], range: NSRange(location: 0, length: verseText.length))
            
            // Add debug border around verse if enabled (using underline which is more visible)
            if showVerseBorders {
                // Background color to make verse boundaries visible
                verseText.addAttribute(
                    .backgroundColor,
                    value: UIColor.systemRed.withAlphaComponent(0.08),
                    range: NSRange(location: 0, length: verseText.length)
                )
                
                // Use underline to show the verse boundary clearly
                verseText.addAttribute(
                    .underlineStyle,
                    value: NSUnderlineStyle.single.rawValue,
                    range: NSRange(location: 0, length: verseText.length)
                )
                verseText.addAttribute(
                    .underlineColor,
                    value: UIColor.systemRed.withAlphaComponent(0.5),
                    range: NSRange(location: 0, length: verseText.length)
                )
            }
            
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
            
            debugLog("interaction", "📌 Text selected: range=\(selectedRange), length=\(selectedRange.length), text='\(selectedText)'")
            
            // Cancel previous debounce
            selectionDebounceTask?.cancel()
            
            // Debounce selection to avoid excessive callbacks
            selectionDebounceTask = Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                try? await Task.sleep(for: .milliseconds(150))
                guard !Task.isCancelled else { return }
                
                // Find which verse this selection belongs to
                if let verse = self.findVerseForSelection(selectedRange, in: textView) {
                    debugLog("interaction", "✅ Found verse \(verse.number) for selection")
                    
                    // Calculate the offset within the verse text
                    let verseOffset = self.calculateVerseOffset(for: verse, selectedRange: selectedRange, in: textView)
                    debugLog("interaction", "📍 Verse offset calculated: \(verseOffset)")
                    
                    // Create adjusted range relative to verse text
                    let adjustedRange = NSRange(location: verseOffset, length: selectedRange.length)
                    
                    self.parent.onTextSelected(verse, adjustedRange, selectedText)
                } else {
                    debugLog("interaction", "❌ Could not find verse for selection at range \(selectedRange)")
                }
            }
        }
        
        /// Find which verse contains the selected range
        private func findVerseForSelection(_ range: NSRange, in textView: UITextView) -> Verse? {
            var currentPosition = 0
            
            for verse in verses {
                // Calculate total length for this verse (number + space + text + newline)
                let verseNumberLength = "\(verse.number) ".count
                let verseTextLength = verse.text.count
                let totalVerseLength = verseNumberLength + verseTextLength + 1 // +1 for newline
                
                let verseRange = NSRange(location: currentPosition, length: totalVerseLength)
                
                debugLog("interaction", "🔍 Checking verse \(verse.number): range=\(verseRange), selection=\(range)")
                
                // Check if selection starts within this verse's range
                if range.location >= currentPosition && range.location < currentPosition + totalVerseLength {
                    debugLog("interaction", "✅ Selection belongs to verse \(verse.number)")
                    
                    // CRITICAL: Check if verse has any interlinear words loaded
                    debugLog("interaction", "📚 Verse \(verse.number) has \(verse.words.count) interlinear words")
                    if verse.words.isEmpty {
                        debugLog("interaction", "⚠️ WARNING: No interlinear data for verse \(verse.number) - data may not be seeded!")
                    } else {
                        debugLog("interaction", "✨ Interlinear words available:")
                        for word in verse.words.prefix(3) {
                            debugLog("interaction", "  - \(word.originalText) (\(word.transliteration)) @ pos \(word.startPosition)-\(word.endPosition)")
                        }
                    }
                    
                    return verse
                }
                
                currentPosition += totalVerseLength
            }
            
            return nil
        }
        
        /// Calculate the offset within the verse text (excluding verse number)
        private func calculateVerseOffset(for verse: Verse, selectedRange: NSRange, in textView: UITextView) -> Int {
            var currentPosition = 0
            
            for v in verses {
                if v.id == verse.id {
                    // Found our verse - calculate offset
                    let verseNumberLength = "\(v.number) ".count
                    let offsetWithinVerse = selectedRange.location - currentPosition - verseNumberLength
                    
                    debugLog("interaction", "🧮 Offset calculation: currentPos=\(currentPosition), verseNumLen=\(verseNumberLength), selection=\(selectedRange.location), offset=\(offsetWithinVerse)")
                    
                    return max(0, offsetWithinVerse)
                }
                
                let verseNumberLength = "\(v.number) ".count
                let verseTextLength = v.text.count
                currentPosition += verseNumberLength + verseTextLength + 1
            }
            
            return 0
        }
    }
}
