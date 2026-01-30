//
//  ImprovedSelectableTextView.swift
//  WrittenWord
//
//  FIXED: Proper text rendering with descender support and wrapping
//  - Prevents "g" and other descenders from being cut off
//  - Ensures text wraps properly at container boundaries
//  - Maintains smooth interaction with annotation mode
//

import SwiftUI
import UIKit

struct ImprovedSelectableTextView: UIViewRepresentable {
    let text: String
    let highlights: [Highlight]
    let fontSize: Double
    let fontFamily: FontFamily
    let lineSpacing: Double
    let colorTheme: ColorTheme
    let isAnnotationMode: Bool
    let availableWidth: CGFloat
    let onHighlight: (NSRange, String) -> Void
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.backgroundColor = .clear
        
        // CRITICAL FIX: Add vertical insets to prevent descender clipping
        // Horizontal insets stay at 0, but we need vertical space for descenders
        let verticalInset: CGFloat = 4 // Extra space for descenders
        textView.textContainerInset = UIEdgeInsets(
            top: verticalInset,
            left: 0,
            bottom: verticalInset,
            right: 0
        )
        textView.textContainer.lineFragmentPadding = 0

        // CRITICAL FIX: Properly configure text container for wrapping
        // Set the width constraint BEFORE any other operations
        textView.textContainer.widthTracksTextView = false  // Don't track - use explicit width
        textView.textContainer.size = CGSize(
            width: availableWidth,
            height: CGFloat.greatestFiniteMagnitude
        )
        textView.textContainer.maximumNumberOfLines = 0
        textView.textContainer.lineBreakMode = .byWordWrapping

        // Allow vertical expansion, but constrain horizontal
        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.required, for: .horizontal)

        // Enable text selection
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true

        // Add long press gesture for highlight menu
        let longPress = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(context.coordinator.handleLongPress(_:))
        )
        longPress.minimumPressDuration = 0.3
        textView.addGestureRecognizer(longPress)

        // Customize selection appearance
        textView.tintColor = UIColor.systemBlue

        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Update container width if it changed
        if uiView.textContainer.size.width != availableWidth {
            uiView.textContainer.size = CGSize(
                width: availableWidth,
                height: CGFloat.greatestFiniteMagnitude
            )
        }

        // Build attributed string
        let attributedText = NSMutableAttributedString(string: text)

        // CRITICAL FIX: Configure paragraph style with proper line height
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        paragraphStyle.alignment = .left
        
        // Set minimum line height to prevent descender clipping
        // This ensures letters like "g", "y", "p", "q" have enough space
        let font = UIFont.systemFont(ofSize: fontSize)
        let minimumLineHeight = font.lineHeight * 1.1 // 10% extra for descenders
        paragraphStyle.minimumLineHeight = minimumLineHeight
        
        // Apply user's line spacing preference (but ensure it's not too tight)
        let adjustedLineSpacing = max(lineSpacing, 2.0) // Minimum 2pt spacing
        paragraphStyle.lineSpacing = adjustedLineSpacing

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor(colorTheme.textColor)
        ]

        attributedText.addAttributes(
            baseAttributes,
            range: NSRange(location: 0, length: attributedText.length)
        )

        // Apply highlights
        for highlight in highlights {
            let range = NSRange(
                location: highlight.startIndex,
                length: highlight.endIndex - highlight.startIndex
            )
            if range.location >= 0 && range.location + range.length <= attributedText.length {
                attributedText.addAttribute(
                    .backgroundColor,
                    value: UIColor(highlight.highlightColor),
                    range: range
                )
            }
        }

        uiView.attributedText = attributedText

        // Disable interaction when in annotation mode
        uiView.isUserInteractionEnabled = !isAnnotationMode

        // Force layout update
        uiView.setNeedsLayout()
        uiView.layoutIfNeeded()
        uiView.invalidateIntrinsicContentSize()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: ImprovedSelectableTextView

        init(_ parent: ImprovedSelectableTextView) {
            self.parent = parent
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            let selectedRange = textView.selectedRange
            
            // Only trigger highlight if there's actual text selected
            if selectedRange.length > 0 {
                if let selectedText = textView.text(in: textView.selectedTextRange!) {
                    // Trigger highlight menu
                    parent.onHighlight(selectedRange, selectedText)
                }
            }
        }
        
        @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
            guard gesture.state == .began else { return }
            
            guard let textView = gesture.view as? UITextView else { return }
            
            let point = gesture.location(in: textView)
            
            // Get the character index at the touch point
            let characterIndex = textView.layoutManager.characterIndex(
                for: point,
                in: textView.textContainer,
                fractionOfDistanceBetweenInsertionPoints: nil
            )
            
            // Select the word at this position
            if characterIndex < textView.text.count {
                let tokenizer = UITextInputStringTokenizer(textInput: textView)
                
                if let wordRange = tokenizer.rangeEnclosingPosition(
                    textView.position(from: textView.beginningOfDocument, offset: characterIndex)!,
                    with: .word,
                    inDirection: .storage(.forward)
                ) {
                    textView.selectedTextRange = wordRange
                    
                    // Calculate NSRange from UITextRange
                    let nsRange = NSRange(
                        location: textView.offset(from: textView.beginningOfDocument, to: wordRange.start),
                        length: textView.offset(from: wordRange.start, to: wordRange.end)
                    )
                    
                    if let selectedText = textView.text(in: wordRange) {
                        parent.onHighlight(nsRange, selectedText)
                    }
                }
            }
        }
        
        // Allow built-in menu for copy/paste
        @available(iOS 17.0, *)
        func textView(
            _ textView: UITextView,
            primaryActionFor textItem: UITextItem,
            defaultAction: UIAction
        ) -> UIAction? {
            return defaultAction
        }
    }
}

// MARK: - Preview Support
#Preview {
    let verse = Verse(number: 1, text: "In the beginning God created the heaven and the earth.")

    return VStack(alignment: .leading, spacing: 20) {
        Text("Try long-pressing or selecting text:")
            .font(.caption)
            .foregroundStyle(.secondary)

        Text("Testing descenders: gypqj")
            .font(.caption)
            .foregroundStyle(.secondary)

        ImprovedSelectableTextView(
            text: verse.text,
            highlights: [],
            fontSize: 16,
            fontFamily: .system,
            lineSpacing: 2, // Minimum spacing to test descender fix
            colorTheme: .system,
            isAnnotationMode: false,
            availableWidth: 300,
            onHighlight: { range, text in
                print("Selected: \(text) at range: \(range)")
            }
        )

        Spacer()
    }
    .padding()
}
