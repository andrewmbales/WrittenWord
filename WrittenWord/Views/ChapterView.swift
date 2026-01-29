//
//  ChapterView.swift
//  WrittenWord
//
//  WORKING: Clean chapter display with verses
//

import SwiftUI
import SwiftData

struct ChapterView: View {
    let chapter: Chapter
    let onChapterChange: (Chapter) -> Void
    
    @AppStorage("fontSize") private var fontSize: Double = 16.0
    @AppStorage("lineSpacing") private var lineSpacing: Double = 6.0
    @AppStorage("fontFamily") private var fontFamily: FontFamily = .system
    
    private var sortedVerses: [Verse] {
        chapter.verses.sorted { $0.number < $1.number }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(sortedVerses) { verse in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(verse.number)")
                            .font(.system(size: fontSize * 0.75))
                            .foregroundStyle(.secondary)
                            .frame(width: 28)
                        
                        Text(verse.text)
                            .font(fontFamily.font(size: fontSize))
                            .lineSpacing(lineSpacing)
                            .textSelection(.enabled)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 20)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("\(chapter.book?.name ?? "") \(chapter.number)")
    }
}
