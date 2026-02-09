//
//  WordSelectableChapterTextView.swift
//  WrittenWord
//
//  ENHANCED: Added margin support for note-taking with proper text wrapping
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
    let leftMargin: Double      // NEW
    let rightMargin: Double     // NEW
    let onTextSelected: (Verse, NSRange, String) -> Void
    
    @AppStorage("showVerseBorders") private var showVerseBorders: Bool = false
        
    func makeUIView(context: Context) -> UITextView {
        #if DEBUG
        print("📱 Creating UITextView with lineSpacing=\(lineSpacing), margins=(\(leftMargin), \(rightMargin))")
        #endif
        
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isEditable = false
        textView.isScrollEnabled = false  // Parent ScrollView handles scrolling
        textView.backgroundColor = .clear
        
        // Apply margins via text container insets
        textView.textContainerInset = UIEdgeInsets(
            top: 20,
            left: leftMargin,
            bottom: 20,
            right: rightMargin
        )
        textView.textContainer.lineFragmentPadding = 0
        
        // Enable proper text wrapping
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.widthTracksTextView = true
        
        // Enable text selection
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true
        textView.tintColor = UIColor.systemBlue

        // Set content priorities for proper wrapping
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        textView.layoutManager.usesFontLeading = true

        return textView
    }
    
    func updateUIView(_ textView: UITextView, context: Context) {
        #if DEBUG
        print("🔄 Updating UITextView: \(verses.count) verses, margins=(\(leftMargin), \(rightMargin))")
        #endif
        
        // Update margins if changed
        let currentInsets = textView.textContainerInset
        let newInsets = UIEdgeInsets(
            top: 20,
            left: leftMargin,
            bottom: 20,
            right: rightMargin
        )
        
        if currentInsets != newInsets {
            textView.textContainerInset = newInsets
        }
        
        // Update coordinator
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
            
            // Line height configuration
            let desiredTotalLineHeight = fontSize + lineSpacing
            let lineHeightMultiplier = desiredTotalLineHeight / fontSize
            
            paragraphStyle.lineHeightMultiple = lineHeightMultiplier
            paragraphStyle.minimumLineHeight = desiredTotalLineHeight
            paragraphStyle.maximumLineHeight = desiredTotalLineHeight
            
            // Verse spacing for debug mode
            if showVerseBorders {
                paragraphStyle.paragraphSpacing = 12
                paragraphStyle.paragraphSpacingBefore = 12
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
                let descriptor = UIFont.systemFont(ofSize: fontSize).fontDescriptor
                    .withDesign(.monospaced) ?? UIFont.systemFont(ofSize: fontSize).fontDescriptor
                font = UIFont(descriptor: descriptor, size: fontSize)
            }
            
            // Base attributes
            let textColor: UIColor
            switch colorTheme {
            case .light, .sepia, .sand:
                textColor = .black
            case .dark:
                textColor = .white
            case .system:
                textColor = .label
            }
            
            verseText.addAttributes([
                .font: font,
                .foregroundColor: textColor,
                .paragraphStyle: paragraphStyle
            ], range: NSRange(location: 0, length: verseText.length))
            
            // Apply highlights
            let verseHighlights = highlights.filter { $0.verseId == verse.id }
            for highlight in verseHighlights {
                let range = NSRange(
                    location: highlight.startIndex,
                    length: highlight.endIndex - highlight.startIndex
                )
                
                if range.location >= 0 && range.location + range.length <= verseText.length {
                    verseText.addAttribute(
                        .backgroundColor,
                        value: UIColor(highlight.highlightColor),
                        range: range
                    )
                }
            }
            
            // Debug: Add verse borders (using background color)
            if showVerseBorders {
                verseText.addAttribute(
                    .underlineStyle,
                    value: NSUnderlineStyle.single.rawValue,
                    range: NSRange(location: 0, length: verseText.length)
                )
                verseText.addAttribute(
                    .underlineColor,
                    value: UIColor.red.withAlphaComponent(0.3),
                    range: NSRange(location: 0, length: verseText.length)
                )
            }
            
            result.append(verseText)
            
            // Add newline between verses
            if index < verses.count - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }
        
        return result
    }
    
    // MARK: - Coordinator
    
    //
    //  Coordinator Fix for WordSelectableChapterTextView
    //
    //  Replace the Coordinator class in WordSelectableChapterTextView.swift with this
    //

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: WordSelectableChapterTextView
        var verses: [Verse]
        
        init(_ parent: WordSelectableChapterTextView) {
            self.parent = parent
            self.verses = parent.verses
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            let selectedRange = textView.selectedRange
            
            guard selectedRange.length > 0 else { return }
            
            // Get selected text
            let nsString = textView.attributedText.string as NSString
            guard selectedRange.location + selectedRange.length <= nsString.length else {
                #if DEBUG
                print("⚠️ Selection range out of bounds")
                #endif
                return
            }
            
            let selectedText = nsString.substring(with: selectedRange)
            
            #if DEBUG
            print("📝 Text selected: '\(selectedText)' at range \(selectedRange.location)-\(selectedRange.location + selectedRange.length)")
            #endif
            
            // Find which verse this selection STARTS in
            guard let verse = findVerse(for: selectedRange, in: textView.attributedText) else {
                #if DEBUG
                print("⚠️ Could not find verse for selection")
                #endif
                return
            }
            
            // Calculate range relative to verse text
            let verseRange = calculateVerseRange(for: verse, in: textView.attributedText.string)
            
            // CRITICAL FIX: Handle selections that span beyond the verse
            let verseEndPosition = verseRange.location + verseRange.length
            let selectionEndPosition = selectedRange.location + selectedRange.length
            
            // If selection extends beyond this verse, truncate it to verse boundary
            let effectiveSelectionEnd = min(selectionEndPosition, verseEndPosition)
            let effectiveSelectionLength = effectiveSelectionEnd - selectedRange.location
            
            // Calculate relative range (within the verse text)
            let relativeLocation = max(0, selectedRange.location - verseRange.location)
            let relativeLength = max(0, min(effectiveSelectionLength, verseRange.length - relativeLocation))
            
            let relativeRange = NSRange(
                location: relativeLocation,
                length: relativeLength
            )
            
            #if DEBUG
            print("📍 Verse \(verse.number): verseRange=\(verseRange), relativeRange=\(relativeRange)")
            #endif
            
            // Only proceed if we have a valid range
            guard relativeRange.length > 0,
                  relativeRange.location >= 0,
                  relativeRange.location + relativeRange.length <= verse.text.count else {
                #if DEBUG
                print("⚠️ Invalid relative range - skipping")
                #endif
                return
            }
            
            parent.onTextSelected(verse, relativeRange, selectedText)
        }
        
        private func findVerse(for range: NSRange, in attributedText: NSAttributedString) -> Verse? {
            var currentPosition = 0
            
            for verse in verses {
                let verseString = "\(verse.number) \(verse.text)"
                let verseLength = verseString.count
                
                let verseRange = NSRange(location: currentPosition, length: verseLength)
                
                // Check if selection STARTS within this verse
                if range.location >= verseRange.location &&
                   range.location < verseRange.location + verseRange.length {
                    return verse
                }
                
                currentPosition += verseLength + 1 // +1 for newline
            }
            
            // If we couldn't find the verse, return the last one (safety fallback)
            return verses.last
        }
        
        private func calculateVerseRange(for verse: Verse, in fullText: String) -> NSRange {
            var currentPosition = 0
            
            for v in verses {
                let verseString = "\(v.number) \(v.text)"
                let verseLength = verseString.count
                
                if v.id == verse.id {
                    return NSRange(location: currentPosition, length: verseLength)
                }
                
                currentPosition += verseLength + 1 // +1 for newline
            }
            
            return NSRange(location: 0, length: 0)
        }
    }
}
