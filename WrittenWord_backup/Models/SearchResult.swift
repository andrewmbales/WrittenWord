//
//  SearchResult.swift
//  WrittenWord
//
//  Phase 2: Global Search Support
//
import Foundation
import SwiftData

// MARK: - Search Result Wrapper
struct SearchResult: Identifiable, Hashable {
    let id = UUID()
    let verse: Verse
    let matchedText: String
    let book: Book
    let chapter: Chapter
    
    var reference: String {
        verse.reference
    }
    
    var contextText: String {
        verse.text
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SearchResult, rhs: SearchResult) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Search Filter Options
enum SearchScope: String, CaseIterable, Identifiable {
    case all = "All"
    case oldTestament = "Old Testament"
    case newTestament = "New Testament"
    case currentBook = "Current Book"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .all: return "book.closed"
        case .oldTestament: return "book"
        case .newTestament: return "book"
        case .currentBook: return "bookmark"
        }
    }
}

enum SearchSortOption: String, CaseIterable, Identifiable {
    case relevance = "Relevance"
    case bookOrder = "Book Order"
    case verseNumber = "Verse Number"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .relevance: return "star.fill"
        case .bookOrder: return "text.book.closed"
        case .verseNumber: return "number"
        }
    }
}

// MARK: - Book Distribution for Charts
struct BookDistribution: Identifiable {
    let id = UUID()
    let book: Book
    let count: Int
    let percentage: Double
}