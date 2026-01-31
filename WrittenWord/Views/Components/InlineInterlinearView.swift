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
                .foregroundStyle(partOfSpeechColor)
                .fontWeight(.medium)

            // Original language and transliteration
            VStack(alignment: .leading, spacing: 1) {
                Text(word.originalText)
                    .font(.system(size: fontSize * 0.7))
                    .foregroundStyle(.secondary)

                Text(word.transliteration)
                    .font(.system(size: fontSize * 0.6))
                    .foregroundStyle(.secondary)
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
