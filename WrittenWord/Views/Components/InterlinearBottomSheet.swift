//
//  InterlinearBottomSheet.swift
//  WrittenWord
//
//  Bottom sheet for displaying lexicon-style word lookup with definitions and verse references
//

import SwiftUI

struct InterlinearBottomSheet: View {
    let word: Word
    let lexiconEntry: LexiconEntry
    let onCopy: () -> Void
    let onAddNote: () -> Void
    let onHighlight: () -> Void
    let onNavigateToVerse: (VerseReference) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                // Dark charcoal background
                Color(red: 0.15, green: 0.15, blue: 0.17)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header Section
                        VStack(alignment: .leading, spacing: 8) {
                            // Greek word - large and bold
                            Text(lexiconEntry.originalText)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)

                            // Transliteration in italics
                            HStack(spacing: 4) {
                                Text("[\(lexiconEntry.transliteration)]")
                                    .font(.system(size: 18))
                                    .italic()
                                    .foregroundColor(.white.opacity(0.8))

                                // Part of speech indicator
                                if let parsed = MorphologyParser.parse(word.morphology ?? "") {
                                    Text(parsed.partOfSpeech.lowercased() + ".")
                                        .font(.system(size: 18))
                                        .italic()
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }

                            // Part of speech label
                            Text(lexiconEntry.partOfSpeechLabel)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.top, 4)

                            // Found X verses indicator
                            Text("Found \(lexiconEntry.totalOccurrences) verses")
                                .font(.system(size: 13))
                                .foregroundColor(.blue.opacity(0.9))
                                .padding(.top, 8)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 24)
                        .padding(.bottom, 20)

                        // Definitions Section
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(lexiconEntry.definitions) { definition in
                                DefinitionRow(
                                    definition: definition,
                                    onNavigateToVerse: onNavigateToVerse
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                        // Source Attribution
                        Text(lexiconEntry.source)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                    }
                }

                // Action Buttons at bottom
                VStack {
                    Spacer()

                    HStack(spacing: 16) {
                        // Copy Button
                        ActionButton(
                            icon: "doc.on.doc",
                            title: "Copy",
                            action: {
                                onCopy()
                                dismiss()
                            }
                        )

                        // Add Note Button
                        ActionButton(
                            icon: "note.text.badge.plus",
                            title: "Add Note",
                            action: {
                                onAddNote()
                                dismiss()
                            }
                        )

                        // Highlight Button
                        ActionButton(
                            icon: "highlighter",
                            title: "Highlight",
                            action: {
                                onHighlight()
                                dismiss()
                            }
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(
                        Color(red: 0.12, green: 0.12, blue: 0.14)
                            .shadow(color: .black.opacity(0.3), radius: 8, y: -4)
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

// MARK: - Definition Row

struct DefinitionRow: View {
    let definition: Definition
    let onNavigateToVerse: (VerseReference) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Main definition
            HStack(alignment: .top, spacing: 8) {
                // Number
                Text("\(definition.number).")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 24, alignment: .leading)

                VStack(alignment: .leading, spacing: 8) {
                    // Meaning
                    Text(definition.meaning)
                        .font(.system(size: 16))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    // Verse references
                    if !definition.verseReferences.isEmpty {
                        VerseReferenceTagsView(
                            references: definition.verseReferences,
                            onTap: onNavigateToVerse
                        )
                    }
                }
            }

            // Sub-definitions
            if !definition.subDefinitions.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(definition.subDefinitions) { subDef in
                        HStack(alignment: .top, spacing: 8) {
                            // Letter (a, b, c, d)
                            Text("\(subDef.letter).")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.8))
                                .frame(width: 40, alignment: .trailing)

                            VStack(alignment: .leading, spacing: 8) {
                                // Sub-meaning
                                Text(subDef.meaning)
                                    .font(.system(size: 15))
                                    .foregroundColor(.white.opacity(0.9))
                                    .fixedSize(horizontal: false, vertical: true)

                                // Sub-definition verse references
                                if !subDef.verseReferences.isEmpty {
                                    VerseReferenceTagsView(
                                        references: subDef.verseReferences,
                                        onTap: onNavigateToVerse
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(.leading, 32)
            }
        }
    }
}

// MARK: - Verse Reference Tags

struct VerseReferenceTagsView: View {
    let references: [VerseReference]
    let onTap: (VerseReference) -> Void

    var body: some View {
        FlowLayout(spacing: 8) {
            ForEach(references) { ref in
                Button {
                    onTap(ref)
                } label: {
                    Text(ref.display)
                        .font(.system(size: 13))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue.opacity(0.15))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                }
            }
        }
    }
}

// MARK: - Action Button

struct ActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.white)

                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.9))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.1))
            )
        }
    }
}

// MARK: - Flow Layout for Tags

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
            subview.place(at: result.positions[index], proposal: .unspecified)
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
                let subviewSize = subview.sizeThatFits(.unspecified)

                if currentX + subviewSize.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                positions.append(CGPoint(x: currentX, y: currentY))
                currentX += subviewSize.width + spacing
                lineHeight = max(lineHeight, subviewSize.height)
            }

            size = CGSize(
                width: maxWidth,
                height: currentY + lineHeight
            )
        }
    }
}

// MARK: - Preview

#Preview {
    let word = Word(
        originalText: "ἄγγελος",
        transliteration: "angelos",
        strongsNumber: "G32",
        gloss: "angel, messenger",
        morphology: "Noun - Nominative Masculine Singular",
        wordIndex: 0,
        startPosition: 0,
        endPosition: 5,
        translatedText: "angel",
        language: "grk"
    )

    let entry = LexiconEntry(
        strongsNumber: "G32",
        originalText: "ἄγγελος",
        transliteration: "angelos",
        partOfSpeechLabel: "ἄγγελος, -ου, ὁ, in LXX",
        definitions: [
            Definition(
                number: 1,
                meaning: "a messenger",
                verseReferences: [
                    VerseReference(book: "Mat", chapter: 11, verse: 10),
                    VerseReference(book: "Luk", chapter: 7, verse: 24)
                ],
                subDefinitions: [
                    SubDefinition(
                        letter: "a",
                        meaning: "in general",
                        verseReferences: [
                            VerseReference(book: "Mat", chapter: 11, verse: 10),
                            VerseReference(book: "Luk", chapter: 7, verse: 24)
                        ]
                    ),
                    SubDefinition(
                        letter: "b",
                        meaning: "specially, of the messengers of God",
                        verseReferences: [
                            VerseReference(book: "Mat", chapter: 1, verse: 20),
                            VerseReference(book: "Luk", chapter: 1, verse: 11)
                        ]
                    )
                ]
            ),
            Definition(
                number: 2,
                meaning: "an angel, a celestial spirit",
                verseReferences: [
                    VerseReference(book: "Mat", chapter: 4, verse: 11),
                    VerseReference(book: "Mat", chapter: 28, verse: 2)
                ],
                subDefinitions: [
                    SubDefinition(
                        letter: "a",
                        meaning: "of God's messengers",
                        verseReferences: [
                            VerseReference(book: "Mat", chapter: 4, verse: 11)
                        ]
                    )
                ]
            )
        ],
        totalOccurrences: 172,
        source: "Abbott-Smith. A Manual Greek Lexicon of the New Testament. Sourced from Tyndale House, Cambridge."
    )

    return InterlinearBottomSheet(
        word: word,
        lexiconEntry: entry,
        onCopy: { print("Copy") },
        onAddNote: { print("Add Note") },
        onHighlight: { print("Highlight") },
        onNavigateToVerse: { ref in print("Navigate to \(ref.display)") }
    )
    .presentationDetents([.medium, .large])
}
