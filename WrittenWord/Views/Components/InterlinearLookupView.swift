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

                        if let strongs = word.strongsNumber {
                            Text(strongs)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
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

                    // Morphology (if available)
                    if let morphology = word.morphology {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Grammar")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(morphology)
                                .font(.body)
                                .foregroundColor(.primary)
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
                                .foregroundColor(.blue)
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
