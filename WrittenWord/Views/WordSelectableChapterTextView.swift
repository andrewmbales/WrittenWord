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
    let leftMargin: Double
    let rightMargin: Double
    let onTextSelected: (Verse, NSRange, String) -> Void
    let onVerseTapped: ((Verse) -> Void)?

    @AppStorage("showVerseBorders") private var showVerseBorders: Bool = false

    init(verses: [Verse],
         highlights: [Highlight],
         fontSize: Double,
         fontFamily: FontFamily,
         lineSpacing: Double,
         colorTheme: ColorTheme,
         leftMargin: Double,
         rightMargin: Double,
         onTextSelected: @escaping (Verse, NSRange, String) -> Void,
         onVerseTapped: ((Verse) -> Void)? = nil) {
        self.verses = verses
        self.highlights = highlights
        self.fontSize = fontSize
        self.fontFamily = fontFamily
        self.lineSpacing = lineSpacing
        self.colorTheme = colorTheme
        self.leftMargin = leftMargin
        self.rightMargin = rightMargin
        self.onTextSelected = onTextSelected
        self.onVerseTapped = onVerseTapped
    }
        
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

        // Tap gesture: short press selects entire verse for highlighting
        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        textView.addGestureRecognizer(tapGesture)

        // Long-press gesture: selects a single word
        let longPressGesture = UILongPressGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        textView.addGestureRecognizer(longPressGesture)

        // Let the long press take priority over the tap
        tapGesture.require(toFail: longPressGesture)

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

        // MARK: - Tap: select entire verse for highlighting

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard gesture.state == .ended,
                  let textView = gesture.view as? UITextView else { return }

            let point = gesture.location(in: textView)
            let characterIndex = textView.layoutManager.characterIndex(
                for: point,
                in: textView.textContainer,
                fractionOfDistanceBetweenInsertionPoints: nil
            )

            guard characterIndex < textView.attributedText.length else { return }

            let dummyRange = NSRange(location: characterIndex, length: 1)
            guard let verse = findVerse(for: dummyRange, in: textView.attributedText) else { return }

            // Clear any native text selection
            textView.selectedRange = NSRange(location: 0, length: 0)

            if let onVerseTapped = parent.onVerseTapped {
                onVerseTapped(verse)
            } else {
                // Fallback: select entire verse text
                let range = NSRange(location: 0, length: verse.text.count)
                parent.onTextSelected(verse, range, verse.text)
            }
        }

        // MARK: - Long press: select a single word

        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began,
                  let textView = gesture.view as? UITextView else { return }

            let point = gesture.location(in: textView)
            let characterIndex = textView.layoutManager.characterIndex(
                for: point,
                in: textView.textContainer,
                fractionOfDistanceBetweenInsertionPoints: nil
            )

            let fullString = textView.attributedText.string as NSString
            guard characterIndex < fullString.length else { return }

            // Find the verse this character belongs to
            let dummyRange = NSRange(location: characterIndex, length: 1)
            guard let verse = findVerse(for: dummyRange, in: textView.attributedText) else { return }
            let verseRange = calculateVerseRange(for: verse, in: fullString as String)

            // Find word boundaries within the full string
            let wordRange = fullString.rangeOfCharacter(from: .whitespaces, options: [], range: NSRange(location: characterIndex, length: fullString.length - characterIndex))
            let wordStart: Int = {
                let beforeRange = fullString.rangeOfCharacter(from: .whitespaces, options: .backwards, range: NSRange(location: 0, length: characterIndex))
                return beforeRange.location == NSNotFound ? verseRange.location : beforeRange.location + beforeRange.length
            }()
            let wordEnd: Int = wordRange.location == NSNotFound ? verseRange.location + verseRange.length : wordRange.location

            guard wordEnd > wordStart else { return }
            let absoluteWordRange = NSRange(location: wordStart, length: wordEnd - wordStart)

            // Clamp to verse boundary
            let clampedStart = max(absoluteWordRange.location, verseRange.location)
            let clampedEnd = min(absoluteWordRange.location + absoluteWordRange.length, verseRange.location + verseRange.length)
            guard clampedEnd > clampedStart else { return }

            let selectedWord = fullString.substring(with: NSRange(location: clampedStart, length: clampedEnd - clampedStart))

            // Convert to verse-relative range
            let relativeLocation = clampedStart - verseRange.location
            let relativeRange = NSRange(location: relativeLocation, length: clampedEnd - clampedStart)

            guard relativeRange.location >= 0,
                  relativeRange.location + relativeRange.length <= verse.text.count else { return }

            // Visually highlight the word in the text view
            textView.selectedRange = NSRange(location: clampedStart, length: clampedEnd - clampedStart)

            parent.onTextSelected(verse, relativeRange, selectedWord)
        }

        // MARK: - Native selection delegate (still needed for drag-select)

        func textViewDidChangeSelection(_ textView: UITextView) {
            let selectedRange = textView.selectedRange

            guard selectedRange.length > 0 else { return }

            // Get selected text
            let nsString = textView.attributedText.string as NSString
            guard selectedRange.location + selectedRange.length <= nsString.length else { return }

            let selectedText = nsString.substring(with: selectedRange)

            // Find which verse this selection STARTS in
            guard let verse = findVerse(for: selectedRange, in: textView.attributedText) else { return }

            // Calculate range relative to verse text
            let verseRange = calculateVerseRange(for: verse, in: textView.attributedText.string)

            let verseEndPosition = verseRange.location + verseRange.length
            let selectionEndPosition = selectedRange.location + selectedRange.length
            let effectiveSelectionEnd = min(selectionEndPosition, verseEndPosition)
            let effectiveSelectionLength = effectiveSelectionEnd - selectedRange.location

            let relativeLocation = max(0, selectedRange.location - verseRange.location)
            let relativeLength = max(0, min(effectiveSelectionLength, verseRange.length - relativeLocation))

            let relativeRange = NSRange(location: relativeLocation, length: relativeLength)

            guard relativeRange.length > 0,
                  relativeRange.location >= 0,
                  relativeRange.location + relativeRange.length <= verse.text.count else { return }

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
