//
//  InterlinearDataVerificationView.swift
//  WrittenWord
//
//  Debug view to verify interlinear data is loaded correctly
//
// Created by Andrew Bales on 2/6/26.
//

import SwiftUI
import SwiftData

struct InterlinearDataVerificationView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var verificationResults: [VerificationResult] = []
    @State private var isLoading = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Status") {
                    if isLoading {
                        HStack {
                            ProgressView()
                            Text("Checking database...")
                                .foregroundStyle(.secondary)
                        }
                    } else if verificationResults.isEmpty {
                        Text("Tap 'Run Verification' to check interlinear data")
                            .foregroundStyle(.secondary)
                    } else {
                        HStack {
                            Image(systemName: verificationResults.allSatisfy { $0.hasWords } ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundColor(verificationResults.allSatisfy { $0.hasWords } ? .green : .orange)
                            Text("\(verificationResults.filter { $0.hasWords }.count) of \(verificationResults.count) checked verses have interlinear data")
                        }
                    }
                }
                
                if !verificationResults.isEmpty {
                    Section("Details") {
                        ForEach(verificationResults) { result in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(result.reference)
                                        .font(.headline)
                                    Spacer()
                                    if result.hasWords {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    } else {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                                
                                if result.hasWords {
                                    Text("\(result.wordCount) words")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    
                                    if let sampleWords = result.sampleWords {
                                        Text(sampleWords)
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                            .lineLimit(2)
                                    }
                                } else {
                                    Text("No interlinear data")
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Interlinear Verification")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Run Verification") {
                        Task {
                            await runVerification()
                        }
                    }
                    .disabled(isLoading)
                }
            }
        }
    }
    
    @MainActor
    private func runVerification() async {
        isLoading = true
        verificationResults = []
        
        // Check sample verses from books likely to have interlinear data
        let testCases: [(book: String, chapter: Int, verse: Int)] = [
            ("John", 1, 1),
            ("John", 1, 2),
            ("John", 1, 14),
            ("Matthew", 1, 1),
            ("Romans", 1, 1),
            ("Jude", 1, 3),
            ("Jude", 1, 4),
            ("Genesis", 1, 1), // Should have Hebrew
            ("Psalm", 23, 1),  // Should have Hebrew
        ]
        
        for testCase in testCases {
            let result = await checkVerse(book: testCase.book, chapter: testCase.chapter, verse: testCase.verse)
            verificationResults.append(result)
        }
        
        isLoading = false
    }
    
    @MainActor
    private func checkVerse(book bookName: String, chapter chapterNum: Int, verse verseNum: Int) async -> VerificationResult {
        do {
            // Find the book
            let bookDescriptor = FetchDescriptor<Book>(
                predicate: #Predicate<Book> { $0.name == bookName }
            )
            guard let book = try modelContext.fetch(bookDescriptor).first else {
                return VerificationResult(
                    reference: "\(bookName) \(chapterNum):\(verseNum)",
                    hasWords: false,
                    wordCount: 0,
                    sampleWords: nil
                )
            }
            
            // Find the chapter
            let chapter = book.chapters.first { $0.number == chapterNum }
            guard let chapter = chapter else {
                return VerificationResult(
                    reference: "\(bookName) \(chapterNum):\(verseNum)",
                    hasWords: false,
                    wordCount: 0,
                    sampleWords: nil
                )
            }
            
            // Find the verse
            let verse = chapter.verses.first { $0.number == verseNum }
            guard let verse = verse else {
                return VerificationResult(
                    reference: "\(bookName) \(chapterNum):\(verseNum)",
                    hasWords: false,
                    wordCount: 0,
                    sampleWords: nil
                )
            }
            
            // Check words
            let wordCount = verse.words.count
            let hasWords = wordCount > 0
            
            let sampleWords: String? = hasWords ? verse.words.prefix(3).map { word in
                "\(word.originalText) (\(word.transliteration)) @ \(word.startPosition)-\(word.endPosition)"
            }.joined(separator: ", ") : nil
            
            return VerificationResult(
                reference: verse.reference,
                hasWords: hasWords,
                wordCount: wordCount,
                sampleWords: sampleWords
            )
            
        } catch {
            print("Error checking verse: \(error)")
            return VerificationResult(
                reference: "\(bookName) \(chapterNum):\(verseNum)",
                hasWords: false,
                wordCount: 0,
                sampleWords: nil
            )
        }
    }
}

struct VerificationResult: Identifiable {
    let id = UUID()
    let reference: String
    let hasWords: Bool
    let wordCount: Int
    let sampleWords: String?
}

#Preview {
    InterlinearDataVerificationView()
        .modelContainer(for: [Book.self, Chapter.self, Verse.self, Word.self])
}
