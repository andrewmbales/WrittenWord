//
//  ImprovedSelectableTextView.swift
//  WrittenWord
//
//  FIXED: Better text selection for highlighting
//  - Long press shows highlight menu immediately
//  - Better visual feedback during selection
//  - Smooth interaction with annotation mode
//

import SwiftUI
import UIKit

struct ImprovedSelectableTextView: UIViewRepresentable {
    let text: String
    let highlights: [Highlight]
    let fontSize: Double
    let fontFamily: FontFamily
    let lineSpacing: Double
    let isAnnotationMode: Bool
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
        
        // FIXED: Enable text selection with better UX
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
        let attributedText = NSMutableAttributedString(string: text)
        
        // Set base font and spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize),
            .paragraphStyle: paragraphStyle
        ]
        
        attributedText.addAttributes(baseAttributes, range: NSRange(location: 0, length: attributedText.length))
        
        // Apply highlights with rounded rectangle background
        for highlight in highlights {
            let range = NSRange(location: highlight.startIndex, length: highlight.endIndex - highlight.startIndex)
            if range.location + range.length <= attributedText.length {
                attributedText.addAttribute(
                    .backgroundColor,
                    value: UIColor(highlight.highlightColor),
                    range: range
                )
            }
        }
        
        uiView.attributedText = attributedText
        
        // FIXED: Disable interaction when in annotation mode to prevent conflicts
        uiView.isUserInteractionEnabled = !isAnnotationMode
        
        // Force layout to calculate proper size
        uiView.setNeedsLayout()
        uiView.layoutIfNeeded()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: ImprovedSelectableTextView
        
        init(_ parent: ImprovedSelectableTextView) {
            self.parent = parent
        }
        
        // FIXED: Better selection handling
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
        
        // FIXED: Long press shows highlight menu immediately
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
        
        ImprovedSelectableTextView(
            text: verse.text,
            highlights: [],
            fontSize: 16,
            fontFamily: .system,
            lineSpacing: 6,
            isAnnotationMode: false,
            onHighlight: { range, text in
                print("Selected: \(text) at range: \(range)")
            }
        )
        
        Spacer()
    }
    .padding()
}
