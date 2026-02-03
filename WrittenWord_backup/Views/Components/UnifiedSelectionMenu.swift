//
//  UnifiedSelectionMenu.swift
//  WrittenWord
//
//  Unified menu for text selection that combines interlinear lookup and highlighting
//

import SwiftUI
import SwiftData

struct UnifiedSelectionMenu: View {
    let selectedText: String
    let selectedWord: Word?
    let verse: Verse
    let range: NSRange
    let existingHighlights: [Highlight]
    let onHighlight: (HighlightColor) -> Void
    let onRemoveHighlight: (HighlightColor) -> Void
    let onCancel: () -> Void

    @State private var showMorphologyDetails = false

    private var parsedMorphology: MorphologyParser.ParsedMorphology? {
        guard let word = selectedWord, let morphology = word.morphology else { return nil }
        return MorphologyParser.parse(morphology)
    }

    private var partOfSpeechColor: Color {
        guard let parsed = parsedMorphology else { return .blue }
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

    // Check if a specific color is already applied to this selection
    private func isHighlighted(with color: HighlightColor) -> Bool {
        return existingHighlights.contains { highlight in
            highlight.startIndex == range.location &&
            highlight.endIndex == range.location + range.length &&
            colorsMatch(highlight.highlightColor, color.color)
        }
    }

    private func colorsMatch(_ c1: Color, _ c2: Color) -> Bool {
        // Simple color comparison - convert to hex and compare
        let uiColor1 = UIColor(c1)
        let uiColor2 = UIColor(c2)
        return uiColor1.cgColor.components?.dropLast() == uiColor2.cgColor.components?.dropLast()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Interlinear Information (if available)
            if let word = selectedWord {
                VStack(alignment: .leading, spacing: 12) {
                    // Selected word
                    Text(selectedText)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Divider()

                    // Original language
                    VStack(alignment: .leading, spacing: 6) {
                        Text(word.originalText)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.primary)

                        Text(word.transliteration)
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .italic()

                        HStack(spacing: 8) {
                            if let strongs = word.strongsNumber {
                                Text(strongs)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(partOfSpeechColor.opacity(0.1))
                                    .foregroundColor(partOfSpeechColor)
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

                        Text(word.gloss)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }

                    // Morphology details (expandable)
                    if let parsed = parsedMorphology {
                        VStack(alignment: .leading, spacing: 8) {
                            Button {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    showMorphologyDetails.toggle()
                                }
                            } label: {
                                HStack {
                                    Text(parsed.fullDescription)
                                        .font(.subheadline)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: showMorphologyDetails ? "chevron.up" : "chevron.down")
                                        .font(.caption)
                                        .foregroundColor(partOfSpeechColor)
                                }
                            }

                            if showMorphologyDetails && !parsed.grammaticalDetails.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(parsed.grammaticalDetails, id: \.term) { detail in
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack {
                                                Text(detail.term)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .textCase(.uppercase)
                                                Text(detail.value)
                                                    .font(.caption)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(partOfSpeechColor)
                                            }
                                            Text(detail.explanation)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(partOfSpeechColor.opacity(0.05))
                                        .cornerRadius(6)
                                    }
                                }
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }
                        }
                    }

                    Divider()
                }
                .padding()
            } else {
                // No interlinear data - show selected text and hint
                VStack(alignment: .leading, spacing: 12) {
                    Text(selectedText)
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Divider()
                }
                .padding()
            }

            // Highlight Color Palette
            VStack(alignment: .leading, spacing: 12) {
                Text("Highlight")
                    .font(.headline)
                    .foregroundColor(.primary)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                    ForEach(HighlightColor.allCases, id: \.self) { color in
                        Button {
                            // Toggle: if already highlighted with this color, remove it
                            if isHighlighted(with: color) {
                                onRemoveHighlight(color)
                            } else {
                                onHighlight(color)
                            }
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(color.color)
                                    .frame(height: 50)
                                    .overlay(
                                        Text(color.rawValue.capitalized)
                                            .font(.caption)
                                            .foregroundColor(.black.opacity(0.7))
                                    )

                                // Checkmark if already highlighted with this color
                                if isHighlighted(with: color) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                        .background(
                                            Circle()
                                                .fill(Color.black.opacity(0.5))
                                                .frame(width: 24, height: 24)
                                        )
                                        .padding(4)
                                }
                            }
                        }
                    }
                }

                // Hint for non-interlinear selections
                if selectedWord == nil {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Text("Select a single word to see original language information")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 8)
                }
            }
            .padding()

            // Cancel button
            Button {
                onCancel()
            } label: {
                Text("Cancel")
                    .font(.body)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .background(Color(.systemBackground))
    }
}

// MARK: - Preview

#Preview {
    let verse = Verse(number: 1, text: "In the beginning was the Word")

    let word = Word(
        originalText: "θεός",
        transliteration: "theos",
        strongsNumber: "G2316",
        gloss: "God, deity",
        morphology: "Noun - Nominative Masculine Singular",
        wordIndex: 0,
        startPosition: 0,
        endPosition: 3,
        translatedText: "God",
        language: "grk",
        verse: verse
    )

    return UnifiedSelectionMenu(
        selectedText: "God",
        selectedWord: word,
        verse: verse,
        range: NSRange(location: 0, length: 3),
        existingHighlights: [],
        onHighlight: { color in
            print("Highlight with \(color)")
        },
        onRemoveHighlight: { color in
            print("Remove highlight \(color)")
        },
        onCancel: {
            print("Cancel")
        }
    )
    .presentationDetents([.medium, .large])
}
