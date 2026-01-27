//
//  Bookmark.swift
//  WrittenWord
//
//  Phase 2: Bookmarks System
//
import Foundation
import SwiftData
import SwiftUI

@Model
final class Bookmark: Identifiable {
    var id: UUID
    var title: String
    var verseId: UUID?
    var chapterId: UUID?
    var category: String
    var color: String // Hex color for visual organization
    var notes: String
    var createdAt: Date
    var isPinned: Bool
    
    // Relationships
    var verse: Verse?
    var chapter: Chapter?
    
    init(title: String = "",
         verse: Verse? = nil,
         chapter: Chapter? = nil,
         category: String = "General",
         color: Color = .blue,
         notes: String = "",
         isPinned: Bool = false) {
        
        self.id = UUID()
        self.title = title
        self.verseId = verse?.id
        self.chapterId = chapter?.id
        self.verse = verse
        self.chapter = chapter
        self.category = category
        // Direct hex conversion to avoid extension ambiguity
        let uiColor = UIColor(color)
        let components = uiColor.cgColor.components ?? [0, 0, 0, 0]
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        self.color = String(format: "#%02X%02X%02X", r, g, b)
        self.notes = notes
        self.createdAt = Date()
        self.isPinned = isPinned
    }
    
    var reference: String {
        if let verse = verse {
            return verse.reference
        } else if let chapter = chapter {
            return chapter.reference
        }
        return "Unknown"
    }
    
    var displayTitle: String {
        if !title.isEmpty {
            return title
        }
        return reference
    }
    
    var categoryColor: Color {
        // Direct hex parsing to avoid extension ambiguity
        var hexSanitized = color.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return .blue
        }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        return Color(red: r, green: g, blue: b)
    }
}

// MARK: - Bookmark Categories
enum BookmarkCategory: String, CaseIterable, Identifiable {
    case general = "General"
    case promise = "Promise"
    case prayer = "Prayer"
    case wisdom = "Wisdom"
    case prophecy = "Prophecy"
    case comfort = "Comfort"
    case memorize = "To Memorize"
    case study = "Study"
    case favorite = "Favorite"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .general: return "bookmark"
        case .promise: return "hand.thumbsup.fill"
        case .prayer: return "hands.sparkles.fill"
        case .wisdom: return "lightbulb.fill"
        case .prophecy: return "crystal.ball.fill"
        case .comfort: return "heart.fill"
        case .memorize: return "brain.head.profile"
        case .study: return "book.fill"
        case .favorite: return "star.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .general: return .blue
        case .promise: return .green
        case .prayer: return .purple
        case .wisdom: return .orange
        case .prophecy: return .indigo
        case .comfort: return .pink
        case .memorize: return .yellow
        case .study: return .brown
        case .favorite: return .red
        }
    }
}