//
//  InlineInterlinearView.swift
//  WrittenWord
//
//  Component for displaying interlinear data inline below each word
//

import SwiftUI

struct InlineInterlinearView: View {
    let verse: Verse
    let fontSize: Double
    let lineSpacing: Double
    let fontFamily: FontFamily
    let colorTheme: ColorTheme
    let onWordTapped: (Word) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Get words sorted by index
            let words = WordLookupService.getWords(for: verse)

            // Display words in a wrapping layout
            FlowLayout(spacing: 16) {
                ForEach(words, id: \.id) { word in
                    InlineWordView(
                        word: word,
                        fontSize: fontSize,
                        fontFamily: fontFamily,
                        colorTheme: colorTheme
                    )
                    .onTapGesture {
                        onWordTapped(word)
                    }
                }
            }
        }
    }
}

/// Individual word display with interlinear data shown below
struct InlineWordView: View {
    let word: Word
    let fontSize: Double
    let fontFamily: FontFamily
    let colorTheme: ColorTheme

    private var parsedMorphology: MorphologyParser.ParsedMorphology? {
        if let morphology = word.morphology {
            return MorphologyParser.parse(morphology)
        }
        return nil
    }

    private var partOfSpeechColor: Color {
        guard let parsed = parsedMorphology else { return .primary }

        switch parsed.color {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "cyan": return .cyan
        case "indigo": return .indigo
        default: return .gray
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // English word
            Text(word.translatedText)
                .font(fontFor(size: fontSize))
                .foregroundColor(partOfSpeechColor)
                .fontWeight(.medium)

            // Original language and transliteration
            VStack(alignment: .leading, spacing: 1) {
                Text(word.originalText)
                    .font(.system(size: fontSize * 0.7))
                    .foregroundColor(.secondary)

                Text(word.transliteration)
                    .font(.system(size: fontSize * 0.6))
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }

    private func fontFor(size: Double) -> Font {
        switch fontFamily {
        case .system:
            return .system(size: size)
        case .serif:
            return .system(size: size, design: .serif)
        case .monospaced:
            return .system(size: size, design: .monospaced)
        case .rounded:
            return .system(size: size, design: .rounded)
        }
    }
}

/// Flow layout for wrapping words across multiple lines
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                     y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += size.width + spacing
                lineHeight = max(lineHeight, size.height)
            }

            self.size = CGSize(
                width: maxWidth,
                height: currentY + lineHeight
            )
        }
    }
}

// MARK: - Preview

#Preview {
    let verse = Verse(
        number: 1,
        text: "In the beginning was the Word, and the Word was with God, and the Word was God."
    )

    // Add sample interlinear data
    let word1 = Word(
        originalText: "ἀρχῇ",
        transliteration: "archē",
        strongsNumber: "G746",
        gloss: "beginning, origin",
        morphology: "Noun - Dative Feminine Singular",
        wordIndex: 0,
        startPosition: 7,
        endPosition: 16,
        translatedText: "beginning",
        language: "grk",
        verse: verse
    )

    let word2 = Word(
        originalText: "ἦν",
        transliteration: "ēn",
        strongsNumber: "G1510",
        gloss: "to be, exist",
        morphology: "V-IAI-3S",
        wordIndex: 1,
        startPosition: 17,
        endPosition: 20,
        translatedText: "was",
        language: "grk",
        verse: verse
    )

    let word3 = Word(
        originalText: "λόγος",
        transliteration: "logos",
        strongsNumber: "G3056",
        gloss: "word, speech, message",
        morphology: "Noun - Nominative Masculine Singular",
        wordIndex: 2,
        startPosition: 25,
        endPosition: 29,
        translatedText: "Word",
        language: "grk",
        verse: verse
    )

    verse.words = [word1, word2, word3]

    return InlineInterlinearView(
        verse: verse,
        fontSize: 16,
        lineSpacing: 6,
        fontFamily: .system,
        colorTheme: .system,
        onWordTapped: { word in
            print("Tapped: \(word.translatedText)")
        }
    )
    .padding()
}
