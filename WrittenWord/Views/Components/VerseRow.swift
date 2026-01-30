//
//  VerseRow.swift
//  WrittenWord
//
//  FIXED: Proper verse display with text wrapping
//  - Ensures text wraps at proper boundaries
//  - Prevents descender clipping
//  - Proper width constraint propagation
//

import SwiftUI
import SwiftData

struct VerseRow: View {
    let verse: Verse
    let fontSize: Double
    let lineSpacing: Double
    let fontFamily: FontFamily
    let colorTheme: ColorTheme
    let isAnnotationMode: Bool
    let isInlineInterlinearMode: Bool
    let onTextSelected: (NSRange, String) -> Void
    let onBookmark: () -> Void
    let onWordTapped: ((Word) -> Void)?

    @Environment(\.modelContext) private var modelContext
    @Query private var allHighlights: [Highlight]

    var verseHighlights: [Highlight] {
        allHighlights.filter { $0.verseId == verse.id }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Verse number with highlight indicator
            VStack(spacing: 4) {
                Text("\(verse.number)")
                    .font(.system(size: fontSize * 0.75, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, alignment: .center)

                // Small dot indicator if verse has highlights
                if !verseHighlights.isEmpty {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 28)

            // Conditional display based on inline mode
            if isInlineInterlinearMode && !verse.words.isEmpty {
                // Show inline interlinear view
                InlineInterlinearView(
                    verse: verse,
                    fontSize: fontSize,
                    lineSpacing: lineSpacing,
                    fontFamily: fontFamily,
                    colorTheme: colorTheme,
                    onWordTapped: { word in
                        onWordTapped?(word)
                    }
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                // Show regular text view
                // CRITICAL FIX: Use flexible frame instead of GeometryReader
                // This allows proper width constraint while enabling wrapping
                ImprovedSelectableTextView(
                    text: verse.text,
                    highlights: verseHighlights,
                    fontSize: fontSize,
                    fontFamily: fontFamily,
                    lineSpacing: lineSpacing,
                    colorTheme: colorTheme,
                    isAnnotationMode: isAnnotationMode,
                    availableWidth: UIScreen.main.bounds.width - 280, // Account for margins and verse number
                    onHighlight: onTextSelected
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(.vertical, max(4, lineSpacing / 3)) // Ensure minimum vertical padding
        .contentShape(Rectangle()) // Makes the entire row tappable
        .contextMenu {
            Button(action: onBookmark) {
                Label("Bookmark Verse", systemImage: "bookmark")
            }

            Button {
                UIPasteboard.general.string = verse.text
            } label: {
                Label("Copy Text", systemImage: "doc.on.doc")
            }

            if !verseHighlights.isEmpty {
                Divider()
                Button(role: .destructive) {
                    removeAllHighlights()
                } label: {
                    Label("Remove All Highlights", systemImage: "trash")
                }
            }
        }
    }

    private func removeAllHighlights() {
        for highlight in verseHighlights {
            modelContext.delete(highlight)
        }
        try? modelContext.save()
    }
}

// MARK: - Alternative Implementation with GeometryReader (if needed)
struct VerseRowWithGeometry: View {
    let verse: Verse
    let fontSize: Double
    let lineSpacing: Double
    let fontFamily: FontFamily
    let colorTheme: ColorTheme
    let isAnnotationMode: Bool
    let onTextSelected: (NSRange, String) -> Void
    let onBookmark: () -> Void
    
    @Query private var allHighlights: [Highlight]
    
    var verseHighlights: [Highlight] {
        allHighlights.filter { $0.verseId == verse.id }
    }
    
    var body: some View {
        // Use overlay to get width without affecting layout
        HStack(alignment: .top, spacing: 12) {
            // Verse number
            VStack(spacing: 4) {
                Text("\(verse.number)")
                    .font(.system(size: fontSize * 0.75, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, alignment: .center)

                if !verseHighlights.isEmpty {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 28)

            // Text view with proper width
            GeometryReader { geometry in
                ImprovedSelectableTextView(
                    text: verse.text,
                    highlights: verseHighlights,
                    fontSize: fontSize,
                    fontFamily: fontFamily,
                    lineSpacing: lineSpacing,
                    colorTheme: colorTheme,
                    isAnnotationMode: isAnnotationMode,
                    availableWidth: geometry.size.width,
                    onHighlight: onTextSelected
                )
            }
            // CRITICAL: Don't use fixedSize - let it size naturally
        }
        .padding(.vertical, max(4, lineSpacing / 3))
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: onBookmark) {
                Label("Bookmark Verse", systemImage: "bookmark")
            }
            
            Button {
                UIPasteboard.general.string = verse.text
            } label: {
                Label("Copy Text", systemImage: "doc.on.doc")
            }
            
            if !verseHighlights.isEmpty {
                Divider()
                Button(role: .destructive) {
                    // Delete highlights
                } label: {
                    Label("Remove Highlights", systemImage: "trash")
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Verse.self,
        Highlight.self,
        configurations: config
    )
    
    let verse = Verse(
        number: 1,
        text: "In the beginning God created the heaven and the earth. Testing descenders: gypqj"
    )
    container.mainContext.insert(verse)
    
    let highlight = Highlight(
        verseId: verse.id,
        startIndex: 17,
        endIndex: 20,
        color: .yellow,
        text: "God",
        verse: verse
    )
    container.mainContext.insert(highlight)
    
    return VStack(spacing: 20) {
        Text("Testing with minimum line spacing:")
            .font(.caption)
        
        VerseRow(
            verse: verse,
            fontSize: 16,
            lineSpacing: 2, // Very tight spacing to test descender fix
            fontFamily: .system,
            colorTheme: .system,
            isAnnotationMode: false,
            isInlineInterlinearMode: false,
            onTextSelected: { range, text in
                print("Selected: \(text)")
            },
            onBookmark: {
                print("Bookmark tapped")
            },
            onWordTapped: { word in
                print("Word tapped: \(word.translatedText)")
            }
        )
        
        Spacer()
    }
    .modelContainer(container)
    .padding()
}
