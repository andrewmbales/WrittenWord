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
    let notePosition: NotePosition
    let isAnnotationMode: Bool
    let onTextSelected: (NSRange, String) -> Void
    let onBookmark: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var allHighlights: [Highlight]

    var verseHighlights: [Highlight] {
        allHighlights.filter { $0.verseId == verse.id }
    }

    var body: some View {
        GeometryReader { geometry in
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

                // Text view with dynamic width calculation
                ImprovedSelectableTextView(
                    text: verse.text,
                    highlights: verseHighlights,
                    fontSize: fontSize,
                    fontFamily: fontFamily,
                    lineSpacing: lineSpacing,
                    colorTheme: colorTheme,
                    isAnnotationMode: isAnnotationMode,
                    availableWidth: calculateAvailableWidth(geometry: geometry),
                    onHighlight: onTextSelected
                )
            }
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
                    removeAllHighlights()
                } label: {
                    Label("Remove All Highlights", systemImage: "trash")
                }
            }
        }
    }

    private func calculateAvailableWidth(geometry: GeometryProxy) -> CGFloat {
        // Start with the full width
        var width = geometry.size.width

        // Subtract verse number and spacing
        width -= 28 + 12

        // Note: padding is already accounted for in the LazyVStack padding in ChapterView
        // No need to subtract it here

        return max(width, 100) // Ensure minimum width
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
            notePosition: .right,
            isAnnotationMode: false,
            onTextSelected: { range, text in
                print("Selected: \(text)")
            },
            onBookmark: {
                print("Bookmark tapped")
            }
        )
        
        Spacer()
    }
    .modelContainer(container)
    .padding()
}
