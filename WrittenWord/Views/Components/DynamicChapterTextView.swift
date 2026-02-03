//
//  DynamicChapterTextView.swift
//  WrittenWord
//
//  FIXED: Proper text display with full width tracking
//  KEEPS: All existing features (selection, highlights, word lookup)
//

import SwiftUI
import SwiftData
import UIKit

struct DynamicChapterTextView: UIViewRepresentable {
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
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        
        textView.textContainerInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        textView.textContainer.lineFragmentPadding = 0
        
        // ✅ FIX: Enable proper text wrapping and width tracking
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.widthTracksTextView = true  // ← KEY FIX

        // Set proper content priorities for wrapping
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        textView.isSelectable = true
        textView.isUserInteractionEnabled = true

        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.verses = verses
        
        let attributedText = buildAttributedText()
        textView.attributedText = attributedText

        // ✅ FIX: Force proper layout
        textView.textContainer.lineBreakMode = .byWordWrapping
        textView.textContainer.maximumNumberOfLines = 0
        
        textView.setNeedsLayout()
        textView.layoutIfNeeded()
        textView.invalidateIntrinsicContentSize()
        textView.sizeToFit()  // ← KEY FIX
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    private func buildAttributedText() -> NSAttributedString {
        let result = NSMutableAttributedString()

        for (index, verse) in verses.enumerated() {
            // Add verse number as superscript
            let verseNumber = NSMutableAttributedString(string: "\(verse.number) ")
            verseNumber.addAttributes([
                .font: UIFont.systemFont(ofSize: fontSize * 0.65, weight: .semibold),
                .foregroundColor: UIColor.systemGray,
                .baselineOffset: fontSize * 0.35
            ], range: NSRange(location: 0, length: verseNumber.length))

            result.append(verseNumber)

            // Add verse text
            let verseText = NSMutableAttributedString(string: verse.text)

            // Apply base styling
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineSpacing = lineSpacing
            paragraphStyle.paragraphSpacing = 6
            paragraphStyle.lineBreakMode = .byWordWrapping

            let font: UIFont
            switch fontFamily {
            case .system:
                font = UIFont.systemFont(ofSize: fontSize)
            case .serif:
                font = UIFont(name: "Georgia", size: fontSize) ?? UIFont.systemFont(ofSize: fontSize)
            case .rounded:
                font = UIFont.systemFont(ofSize: fontSize, weight: .regular)
                    .withTraits(.traitBold, size: fontSize, design: .rounded)
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

            // Add space between verses (but not after the last one)
            if index < verses.count - 1 {
                result.append(NSAttributedString(string: " "))
            }
        }

        return result
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: DynamicChapterTextView
        var verses: [Verse]
        private var selectionDebounceTask: Task<Void, Never>?

        init(_ parent: DynamicChapterTextView) {
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
                // Account for verse number and space
                let verseNumberLength = "\(verse.number) ".count
                let verseTextLength = verse.text.count
                let totalLength = verseNumberLength + verseTextLength + 1 // +1 for space after verse

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
                    // Return range starting after verse number
                    return NSRange(
                        location: currentPos + verseNumberLength,
                        length: v.text.count
                    )
                }

                let verseTextLength = v.text.count
                currentPos += verseNumberLength + verseTextLength + 1
            }

            return NSRange(location: 0, length: 0)
        }
    }
}

// MARK: - Helper Extensions
/*
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
*/