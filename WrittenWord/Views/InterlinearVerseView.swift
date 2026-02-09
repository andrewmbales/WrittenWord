//
//  InterlinearVerseView.swift
//  WrittenWord
//
//  Created by Andrew Bales on 2/9/26.
//


import SwiftUI
import SwiftData

struct InterlinearVerseView: View {
    let verse: Verse
    let fontSize: Double
    let fontFamily: FontFamily
    let colorTheme: ColorTheme
    let onWordTapped: (Word) -> Void

    @AppStorage("leftMargin") private var leftMargin: Double = 40.0
    @AppStorage("rightMargin") private var rightMargin: Double = 40.0

    private var words: [Word] {
        verse.words.sorted { $0.wordIndex < $1.wordIndex }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Verse number
            Text("\(verse.number)")
                .font(.system(size: fontSize * 0.75, weight: .bold))
                .foregroundStyle(.secondary)

            // Interlinear content
            if words.isEmpty {
                // Fallback: Show plain text if no interlinear data
                Text(verse.text)
                    .font(.system(size: fontSize))
                    .foregroundColor(colorTheme.textColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Show interlinear words
                InterlinearWordFlow(
                    words: words,
                    fontSize: fontSize,
                    fontFamily: fontFamily,
                    colorTheme: colorTheme,
                    onWordTapped: onWordTapped
                )
            }
        }
        .padding(.vertical, 8)
        .padding(.leading, leftMargin)
        .padding(.trailing, rightMargin)
    }
}

// Flow layout for interlinear words
struct InterlinearWordFlow: View {
    let words: [Word]
    let fontSize: Double
    let fontFamily: FontFamily
    let colorTheme: ColorTheme
    let onWordTapped: (Word) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Use FlowLayout if available, otherwise VStack
            FlowLayout(spacing: 8) {
                ForEach(words, id: \.id) { word in
                    InterlinearWordBlock(
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
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Individual word block showing original + translation
struct InterlinearWordBlock: View {
    let word: Word
    let fontSize: Double
    let fontFamily: FontFamily
    let colorTheme: ColorTheme

    var body: some View {
        VStack(alignment: .center, spacing: 2) {
            // English translation (on top)
            Text(word.translatedText)
                .font(.system(size: fontSize))
                .foregroundColor(colorTheme.textColor)

            // Original language text below (Greek/Hebrew)
            Text(word.originalText)
                .font(.system(size: fontSize * 0.75, design: .serif))
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(6)
    }
}
