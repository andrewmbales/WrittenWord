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

struct ImprovedSelectableTextView: View {
    let text: String
    let highlights: [Highlight]
    let fontSize: Double
    let fontFamily: FontFamily
    let lineSpacing: Double
    let colorTheme: ColorTheme
    let isAnnotationMode: Bool
    let onHighlight: (NSRange, String) -> Void

    var body: some View {
        GeometryReader { geometry in
            ImprovedTextViewRepresentable(
                text: text,
                highlights: highlights,
                fontSize: fontSize,
                fontFamily: fontFamily,
                lineSpacing: lineSpacing,
                colorTheme: colorTheme,
                isAnnotationMode: isAnnotationMode,
                availableWidth: geometry.size.width,
                onHighlight: onHighlight
            )
        }
    }
}

struct ImprovedTextViewRepresentable: UIViewRepresentable {
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
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0

        // CRITICAL: Set explicit container size for wrapping
        textView.textContainer.size = CGSize(width: availableWidth, height: .greatestFiniteMagnitude)
        textView.textContainer.widthTracksTextView = false
        textView.textContainer.heightTracksTextView = true

        textView.setContentHuggingPriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.required, for: .vertical)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

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
        // Update container size if width changed
        if abs(uiView.textContainer.size.width - availableWidth) > 0.1 {
            uiView.textContainer.size = CGSize(width: availableWidth, height: .greatestFiniteMagnitude)
        }

        // Store current values in coordinator to detect changes
        let valuesChanged = context.coordinator.updateValues(
            lineSpacing: lineSpacing,
            fontSize: fontSize,
            text: text
        )

        // Build attributed string
        let attributedText = NSMutableAttributedString(string: text)

        // Set base font and spacing
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = lineSpacing
        paragraphStyle.lineBreakMode = .byWordWrapping

        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: fontSize),
            .paragraphStyle: paragraphStyle,
            .foregroundColor: UIColor(colorTheme.textColor)
        ]

        attributedText.addAttributes(baseAttributes, range: NSRange(location: 0, length: attributedText.length))

        // Apply highlights
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

        // Disable interaction when in annotation mode
        uiView.isUserInteractionEnabled = !isAnnotationMode

        // CRITICAL: Force complete layout recalculation when values change
        if valuesChanged {
            uiView.textContainer.size = CGSize(width: availableWidth, height: .greatestFiniteMagnitude)
            uiView.invalidateIntrinsicContentSize()
            uiView.sizeToFit()

            // Force parent view to re-layout
            DispatchQueue.main.async {
                uiView.invalidateIntrinsicContentSize()
            }
        }
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        // Return the intrinsic content size for proper SwiftUI layout
        let size = uiView.sizeThatFits(CGSize(width: proposal.width ?? availableWidth, height: .greatestFiniteMagnitude))
        return CGSize(width: proposal.width ?? availableWidth, height: size.height)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: ImprovedTextViewRepresentable

        // Track previous values to detect changes
        private var previousLineSpacing: Double = 0
        private var previousFontSize: Double = 0
        private var previousText: String = ""

        init(_ parent: ImprovedTextViewRepresentable) {
            self.parent = parent
        }

        func updateValues(lineSpacing: Double, fontSize: Double, text: String) -> Bool {
            let changed = abs(lineSpacing - previousLineSpacing) > 0.01 ||
                         abs(fontSize - previousFontSize) > 0.01 ||
                         text != previousText

            previousLineSpacing = lineSpacing
            previousFontSize = fontSize
            previousText = text

            return changed
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
            colorTheme: .system,
            isAnnotationMode: false,
            onHighlight: { range, text in
                print("Selected: \(text) at range: \(range)")
            }
        )
        
        Spacer()
    }
    .padding()
}
