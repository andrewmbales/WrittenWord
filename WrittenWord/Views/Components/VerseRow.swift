//
//  VerseRow.swift
//  WrittenWord
//
//  Individual verse display component with highlighting support
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
    let onTextSelected: (NSRange, String) -> Void
    let onBookmark: () -> Void
    
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
            
            // Verse text with selection and highlighting
            ImprovedSelectableTextView(
                text: verse.text,
                highlights: verseHighlights,
                fontSize: fontSize,
                fontFamily: fontFamily,
                lineSpacing: lineSpacing,
                isAnnotationMode: isAnnotationMode,
                onHighlight: onTextSelected
            )
            .id("\(verse.id)-\(lineSpacing)-\(fontSize)")
            .foregroundColor(colorTheme.textColor)
        }
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
                    // This would delete highlights - implement in view model
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
        text: "In the beginning God created the heaven and the earth."
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
    
    return VerseRow(
        verse: verse,
        fontSize: 16,
        lineSpacing: 6,
        fontFamily: .system,
        colorTheme: .system,
        isAnnotationMode: false,
        onTextSelected: { range, text in
            print("Selected: \(text)")
        },
        onBookmark: {
            print("Bookmark tapped")
        }
    )
    .modelContainer(container)
    .padding()
}