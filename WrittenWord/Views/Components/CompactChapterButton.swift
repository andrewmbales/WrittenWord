//
//  CompactChapterButton.swift
//  WrittenWord
//
//  Compact chapter button for sidebar navigation
//

import SwiftUI
import SwiftData

struct CompactChapterButton: View {
    let chapter: Chapter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            print("🔘 Chapter button tapped: \(chapter.number)")
            action()
        }) {
            Text("\(chapter.number)")
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .frame(width: 40, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
                )
        }
        .buttonStyle(.plain) // CRITICAL: Ensures button works inside List
    }
}

// MARK: - Preview
#Preview {
    let chapter = Chapter(number: 1, book: nil)

    VStack(spacing: 16) {
        Text("Normal state:")
        CompactChapterButton(
            chapter: chapter,
            isSelected: false
        ) {
            print("Tapped chapter 1")
        }

        Text("Selected state:")
        CompactChapterButton(
            chapter: chapter,
            isSelected: true
        ) {
            print("Tapped chapter 1")
        }
    }
    .padding()
}