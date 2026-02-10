//
//  InterlinearBottomSheet.swift
//  WrittenWord
//
//  Enhanced bottom sheet with draggable height, snap points, and copy functionality
//

import SwiftUI

struct InterlinearBottomSheet: View {
    let word: Word
    let onDismiss: () -> Void

    @AppStorage("colorTheme") private var colorTheme: ColorTheme = .system

    // Snap point heights
    private let peekHeight: CGFloat = 180
    private let mediumHeight: CGFloat = 400
    private let largeHeight: CGFloat = 600
    
    @State private var currentHeight: CGFloat = 400 // Start at medium
    @State private var dragOffset: CGFloat = 0
    @State private var showMorphologyDetails = false
    @State private var showCopyConfirmation = false
    @State private var copiedItem: String = ""
    
    private var parsedMorphology: MorphologyParser.ParsedMorphology? {
        guard let morphology = word.morphology else { return nil }
        return MorphologyParser.parse(morphology)
    }
    
    private var partOfSpeechColor: Color {
        guard let parsed = parsedMorphology else { return .gray }
        
        // Convert color string to SwiftUI Color
        switch parsed.color.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "red": return .red
        case "yellow": return .yellow
        case "indigo": return .indigo
        case "cyan": return .cyan
        case "gray": return .gray
        default: return .blue
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Left spacer (25%)
                Spacer()
                
                // Center sheet (50%)
                VStack(spacing: 0) {
                    // Drag handle
                    dragHandle
                    
                    // Content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Header
                            header
                            
                            Divider()
                            
                            // Quick actions - Copy buttons
                            quickActionsSection
                            
                            Divider()
                            
                            // Transliteration & Metadata
                            transliterationSection
                            
                            Divider()
                            
                            // Translation
                            translationSection
                            
                            Divider()
                            
                            // Gloss/Definition
                            glossSection
                            
                            // Morphology (only visible at medium/large)
                            if currentHeight >= mediumHeight - 50 {
                                if let parsed = parsedMorphology {
                                    Divider()
                                    morphologySection(parsed: parsed)
                                }
                            }
                            
                            // Language indicator
                            languageIndicator
                            
                            // Size hint at peek
                            if currentHeight < peekHeight + 50 {
                                Text("Pull up for more details")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.top, 8)
                            }
                            
                            // Bottom padding
                            Color.clear.frame(height: 20)
                        }
                        .padding(.vertical)
                    }
                }
                .frame(width: max(0, geometry.size.width * 0.5), height: max(0, currentHeight + dragOffset))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorTheme.backgroundColor)
                        .shadow(color: .black.opacity(0.15), radius: 10, y: -3)
                )
                .overlay(
                    // Copy confirmation toast
                    copyConfirmationToast
                        .opacity(showCopyConfirmation ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: showCopyConfirmation)
                    , alignment: .top
                )
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            dragOffset = value.translation.height
                        }
                        .onEnded { value in
                            snapToNearestDetent(dragVelocity: value.predictedEndTranslation.height)
                            dragOffset = 0
                        }
                )
                
                // Right spacer (25%)
                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentHeight)
        }
        .allowsHitTesting(true)
    }
    
    // MARK: - Components
    
    private var dragHandle: some View {
        RoundedRectangle(cornerRadius: 3)
            .fill(Color.secondary.opacity(0.3))
            .frame(width: 36, height: 5)
            .padding(.top, 8)
            .padding(.bottom, 12)
    }
    
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Word Lookup")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(word.originalText)
                    .font(.system(size: 32, weight: .semibold))
            }
            
            Spacer()
            
            // Size controls
            HStack(spacing: 12) {
                // Expand/Collapse buttons
                Button {
                    withAnimation {
                        currentHeight = currentHeight >= largeHeight ? mediumHeight : largeHeight
                    }
                } label: {
                    Image(systemName: currentHeight >= largeHeight ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    CopyButton(
                        label: "Original",
                        text: word.originalText,
                        icon: "doc.on.doc",
                        color: partOfSpeechColor,
                        onCopy: { showCopyFeedback("Original text") }
                    )
                    
                    CopyButton(
                        label: "Transliteration",
                        text: word.transliteration,
                        icon: "textformat.abc",
                        color: .blue,
                        onCopy: { showCopyFeedback("Transliteration") }
                    )
                    
                    if let strongsNumber = word.strongsNumber {
                        CopyButton(
                            label: "Strong's",
                            text: strongsNumber,
                            icon: "number",
                            color: .purple,
                            onCopy: { showCopyFeedback("Strong's number") }
                        )
                    }
                    
                    CopyButton(
                        label: "Meaning",
                        text: word.gloss,
                        icon: "quote.bubble",
                        color: .orange,
                        onCopy: { showCopyFeedback("Meaning") }
                    )
                    
                    CopyButton(
                        label: "All",
                        text: formatFullWordInfo(),
                        icon: "doc.on.clipboard",
                        color: .green,
                        onCopy: { showCopyFeedback("All information") }
                    )
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var transliterationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Transliteration")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(word.transliteration)
                        .font(.title3)
                        .italic()
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    if let strongsNumber = word.strongsNumber {
                        Text(strongsNumber)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                    
                    if let parsed = parsedMorphology {
                        HStack(spacing: 4) {
                            Image(systemName: parsed.icon)
                                .font(.caption)
                            Text(parsed.partOfSpeech)
                                .font(.caption)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(partOfSpeechColor.opacity(0.15))
                        .foregroundColor(partOfSpeechColor)
                        .cornerRadius(4)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private var translationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Translated As")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(word.translatedText)
                .font(.title2)
                .foregroundColor(.primary)
        }
        .padding(.horizontal)
    }
    
    private var glossSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Meaning")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(word.gloss)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding(.horizontal)
    }
    
    private func morphologySection(parsed: MorphologyParser.ParsedMorphology) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Grammar")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showMorphologyDetails.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(showMorphologyDetails ? "Hide Details" : "Show Details")
                            .font(.caption)
                        Image(systemName: showMorphologyDetails ? "chevron.up" : "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(partOfSpeechColor)
                }
            }
            .padding(.horizontal)
            
            Text(parsed.fullDescription)
                .font(.body)
                .foregroundColor(.primary)
                .padding(.horizontal)
            
            if showMorphologyDetails && !parsed.grammaticalDetails.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(parsed.grammaticalDetails, id: \.term) { detail in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(detail.term)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .textCase(.uppercase)
                                
                                Text(detail.value)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(partOfSpeechColor)
                            }
                            
                            Text(detail.explanation)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.05))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
    
    private var languageIndicator: some View {
        HStack {
            Image(systemName: languageIcon)
                .foregroundColor(partOfSpeechColor)
            Text(languageName)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // Show current size hint
            Text(sizeLabel)
                .font(.caption2)
                .foregroundColor(.secondary.opacity(0.6))
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var copyConfirmationToast: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text("Copied \(copiedItem)")
                .font(.subheadline)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorTheme.backgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 5)
        )
        .padding(.top, 16)
    }
    
    // MARK: - Helpers
    
    private var sizeLabel: String {
        if currentHeight >= largeHeight - 50 {
            return "Large"
        } else if currentHeight >= mediumHeight - 50 {
            return "Medium"
        } else {
            return "Peek"
        }
    }
    
    private func snapToNearestDetent(dragVelocity: CGFloat) {
        let newHeight = currentHeight + dragOffset
        
        // Determine snap point based on velocity and position
        if dragVelocity < -500 {
            // Fast swipe down - dismiss
            onDismiss()
            return
        } else if dragVelocity > 500 {
            // Fast swipe up - go to next larger size
            if currentHeight < mediumHeight {
                currentHeight = mediumHeight
            } else if currentHeight < largeHeight {
                currentHeight = largeHeight
            }
            return
        }
        
        // Snap to nearest detent based on position
        let distances = [
            (peekHeight, abs(newHeight - peekHeight)),
            (mediumHeight, abs(newHeight - mediumHeight)),
            (largeHeight, abs(newHeight - largeHeight))
        ]
        
        let nearest = distances.min(by: { $0.1 < $1.1 })
        
        if let targetHeight = nearest?.0 {
            // If dragging down below peek, dismiss
            if newHeight < peekHeight - 50 {
                onDismiss()
            } else {
                currentHeight = targetHeight
            }
        }
    }
    
    private func formatFullWordInfo() -> String {
        var info = "\(word.originalText) (\(word.transliteration))\n"
        
        if let strongsNumber = word.strongsNumber {
            info += "\(strongsNumber)\n"
        }
        
        info += "Translated: \(word.translatedText)\n"
        info += "Meaning: \(word.gloss)\n"
        
        if let morphology = word.morphology {
            info += "Grammar: \(morphology)"
        }
        
        return info
    }
    
    private func showCopyFeedback(_ item: String) {
        copiedItem = item
        showCopyConfirmation = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showCopyConfirmation = false
        }
    }
    
    private var languageName: String {
        switch word.language {
        case "grk":
            return "Greek"
        case "heb":
            return "Hebrew"
        case "arc":
            return "Aramaic"
        default:
            return word.language
        }
    }
    
    private var languageIcon: String {
        switch word.language {
        case "grk":
            return "character.book.closed"
        case "heb":
            return "character.book.closed.fill"
        case "arc":
            return "character.book.closed"
        default:
            return "book"
        }
    }
}

// MARK: - Copy Button Component

struct CopyButton: View {
    let label: String
    let text: String
    let icon: String
    let color: Color
    let onCopy: () -> Void
    
    var body: some View {
        Button {
            UIPasteboard.general.string = text
            onCopy()
        } label: {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80, height: 70)
            .background(color.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.2)
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            
            InterlinearBottomSheet(
                word: Word(
                    originalText: "λόγος",
                    transliteration: "logos",
                    strongsNumber: "G3056",
                    gloss: "word, speech, divine utterance",
                    morphology: "N-NSM",
                    wordIndex: 4,
                    startPosition: 25,
                    endPosition: 29,
                    translatedText: "Word",
                    language: "grk"
                ),
                onDismiss: {}
            )
        }
    }
}
