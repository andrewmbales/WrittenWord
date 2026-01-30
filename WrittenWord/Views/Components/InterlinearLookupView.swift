//
//  InterlinearLookupView.swift
//  WrittenWord
//
//  View for displaying original language word information (interlinear lookup)
//

import SwiftUI

struct InterlinearLookupView: View {
    let word: Word
    @Environment(\.dismiss) var dismiss
    @State private var showMorphologyDetails = false

    private var parsedMorphology: MorphologyParser.ParsedMorphology? {
        if let morphology = word.morphology {
            return MorphologyParser.parse(morphology)
        }
        return nil
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

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Original Language Word
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Original Language")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(word.originalText)
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(.primary)

                        Text(word.transliteration)
                            .font(.title3)
                            .foregroundColor(.secondary)

                        HStack {
                            if let strongs = word.strongsNumber {
                                Text(strongs)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(partOfSpeechColor.opacity(0.1))
                                    .foregroundColor(partOfSpeechColor)
                                    .cornerRadius(4)
                            }

                            // Part of speech badge
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

                    Divider()

                    // Translation
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Translated As")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(word.translatedText)
                            .font(.title2)
                            .foregroundColor(.primary)
                    }

                    Divider()

                    // Gloss/Definition
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Meaning")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(word.gloss)
                            .font(.body)
                            .foregroundColor(.primary)
                    }

                    // Enhanced Morphology Section (if available)
                    if let parsed = parsedMorphology {
                        Divider()

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

                            // Full description
                            Text(parsed.fullDescription)
                                .font(.body)
                                .foregroundColor(.primary)

                            // Expandable grammatical details
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
                                                .padding(.leading, 8)
                                                .padding(.vertical, 2)
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(partOfSpeechColor.opacity(0.05))
                                        .cornerRadius(8)
                                    }
                                }
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }

                            // Raw morphology code (for reference)
                            if let morphology = word.morphology {
                                Text("Code: \(morphology)")
                                    .font(.caption2)
                                    .foregroundColor(.tertiary)
                                    .padding(.top, 4)
                            }
                        }
                    }

                    // Language Info
                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Language")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack {
                            Image(systemName: languageIcon)
                                .foregroundColor(partOfSpeechColor)
                            Text(languageName)
                                .font(.body)
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Word Lookup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
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

#Preview {
    InterlinearLookupView(
        word: Word(
            originalText: "ἀρχῇ",
            transliteration: "archē",
            strongsNumber: "G746",
            gloss: "beginning, origin",
            morphology: "Noun - Dative Feminine Singular",
            wordIndex: 2,
            startPosition: 7,
            endPosition: 16,
            translatedText: "beginning",
            language: "grk"
        )
    )
}
