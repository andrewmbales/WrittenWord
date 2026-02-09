//
//  SearchResult.swift
//  WrittenWord
//
//  Phase 2: Global Search Support
//
import Foundation
import SwiftData
import SwiftUI

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

// MARK: - Bible Section Groups
enum BibleSection: String, CaseIterable, Identifiable {
    case pentateuch = "Pentateuch"
    case history = "History"
    case wisdomAndPoetry = "Wisdom and Poetry"
    case majorProphets = "Major Prophets"
    case minorProphets = "Minor Prophets"
    case gospelsAndActs = "Gospels and Acts"
    case paulineEpistles = "Pauline Epistles"
    case generalEpistles = "General Epistles"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .pentateuch:       return Color(red: 0.55, green: 0.27, blue: 0.07)
        case .history:          return Color(red: 0.80, green: 0.50, blue: 0.20)
        case .wisdomAndPoetry:  return Color(red: 0.20, green: 0.60, blue: 0.35)
        case .majorProphets:    return Color(red: 0.17, green: 0.40, blue: 0.70)
        case .minorProphets:    return Color(red: 0.50, green: 0.70, blue: 0.90)
        case .gospelsAndActs:   return Color(red: 0.80, green: 0.20, blue: 0.20)
        case .paulineEpistles:  return Color(red: 0.60, green: 0.20, blue: 0.60)
        case .generalEpistles:  return Color(red: 0.85, green: 0.55, blue: 0.15)
        }
    }

    /// Book order ranges (standard 66-book Protestant canon)
    var orderRange: ClosedRange<Int> {
        switch self {
        case .pentateuch:       return 1...5
        case .history:          return 6...17
        case .wisdomAndPoetry:  return 18...22
        case .majorProphets:    return 23...27
        case .minorProphets:    return 28...39
        case .gospelsAndActs:   return 40...44
        case .paulineEpistles:  return 45...58
        case .generalEpistles:  return 59...66
        }
    }

    static func section(for bookOrder: Int) -> BibleSection? {
        allCases.first { $0.orderRange.contains(bookOrder) }
    }
}