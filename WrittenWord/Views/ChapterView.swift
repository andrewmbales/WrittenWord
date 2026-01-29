//
//  ChapterView.swift
//  WrittenWord
//
//  Enhanced chapter display with interlinear word lookup support
//

import SwiftUI
import SwiftData

struct ChapterView: View {
    let chapter: Chapter
    let onChapterChange: (Chapter) -> Void

    @AppStorage("fontSize") private var fontSize: Double = 16.0
    @AppStorage("lineSpacing") private var lineSpacing: Double = 6.0
    @AppStorage("fontFamily") private var fontFamily: FontFamily = .system
    @AppStorage("colorTheme") private var colorTheme: ColorTheme = .system

    @Environment(\.modelContext) private var modelContext

    // State for interlinear word lookup
    @State private var selectedWord: Word?
    @State private var showInterlinearLookup = false
    @State private var selectedVerse: Verse?

    // State for highlighting (fallback when no interlinear data)
    @State private var showHighlightMenu = false
    @State private var selectedText = ""
    @State private var selectedRange: NSRange?
    @State private var selectedHighlightColor: HighlightColor = .yellow

    private var sortedVerses: [Verse] {
        chapter.verses.sorted { $0.number < $1.number }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(sortedVerses) { verse in
                    VerseRow(
                        verse: verse,
                        fontSize: fontSize,
                        lineSpacing: lineSpacing,
                        fontFamily: fontFamily,
                        colorTheme: colorTheme,
                        isAnnotationMode: false,
                        onTextSelected: { range, text in
                            handleTextSelection(verse: verse, range: range, text: text)
                        },
                        onBookmark: {
                            bookmarkVerse(verse)
                        }
                    )
                    .padding(.vertical, 4)
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("\(chapter.book?.name ?? "") \(chapter.number)")
        .sheet(isPresented: $showInterlinearLookup) {
            if let word = selectedWord {
                InterlinearLookupView(word: word)
            }
        }
        .sheet(isPresented: $showHighlightMenu) {
            highlightMenuView
        }
    }

    private var highlightMenuView: some View {
        VStack(spacing: 20) {
            Text("Highlight Text")
                .font(.headline)

            Text(selectedText)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

            // Color palette
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 12) {
                ForEach(HighlightColor.allCases, id: \.self) { color in
                    Button {
                        createHighlight(color: color)
                    } label: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color.color)
                            .frame(height: 50)
                            .overlay(
                                Text(color.rawValue.capitalized)
                                    .font(.caption)
                                    .foregroundColor(.black.opacity(0.7))
                            )
                    }
                }
            }
            .padding()

            Button("Cancel") {
                showHighlightMenu = false
            }
            .padding()
        }
        .padding()
        .presentationDetents([.medium])
    }

    private func handleTextSelection(verse: Verse, range: NSRange, text: String) {
        selectedVerse = verse
        selectedRange = range
        selectedText = text

        // Check if we have interlinear data for this word
        if let word = WordLookupService.findWord(in: verse, for: range) {
            // Show interlinear lookup
            selectedWord = word
            showInterlinearLookup = true
        } else {
            // Fallback to highlighting menu
            showHighlightMenu = true
        }
    }

    private func createHighlight(color: HighlightColor) {
        guard let verse = selectedVerse,
              let range = selectedRange else {
            return
        }

        let highlight = Highlight(
            verseId: verse.id,
            startIndex: range.location,
            endIndex: range.location + range.length,
            color: color.color,
            text: selectedText,
            verse: verse
        )

        modelContext.insert(highlight)
        try? modelContext.save()

        showHighlightMenu = false
        selectedRange = nil
        selectedText = ""
        selectedVerse = nil
    }

    private func bookmarkVerse(_ verse: Verse) {
        let bookmark = Bookmark(
            title: "",
            verse: verse,
            category: BookmarkCategory.general.rawValue,
            color: BookmarkCategory.general.color
        )
        modelContext.insert(bookmark)
        try? modelContext.save()
    }
}
