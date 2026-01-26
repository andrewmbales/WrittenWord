//
//  Highlight.swift
//  WrittenWord
//
//  Created for Phase 1 improvements
//
import Foundation
import SwiftData
import SwiftUI

@Model
final class Highlight: Identifiable {
    var id: UUID
    var verseId: UUID
    var startIndex: Int
    var endIndex: Int
    var color: String // Stored as hex string
    var text: String
    var createdAt: Date
    
    // Relationship
    var verse: Verse?
    
    init(verseId: UUID, 
         startIndex: Int, 
         endIndex: Int, 
         color: Color,
         text: String,
         verse: Verse? = nil) {
        self.id = UUID()
        self.verseId = verseId
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.color = color.toHex()
        self.text = text
        self.createdAt = Date()
        self.verse = verse
    }
    
    var highlightColor: Color {
        Color(hex: color) ?? .yellow
    }
}

// MARK: - Color Extensions
extension Color {
    func toHex() -> String {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 0]
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return nil
        }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Highlight Colors
enum HighlightColor: String, CaseIterable {
    case yellow = "Yellow"
    case green = "Green"
    case blue = "Blue"
    case pink = "Pink"
    case orange = "Orange"
    case purple = "Purple"
    
    var color: Color {
        switch self {
        case .yellow: return Color.yellow.opacity(0.4)
        case .green: return Color.green.opacity(0.4)
        case .blue: return Color.blue.opacity(0.4)
        case .pink: return Color.pink.opacity(0.4)
        case .orange: return Color.orange.opacity(0.4)
        case .purple: return Color.purple.opacity(0.4)
        }
    }
    
    var icon: String {
        switch self {
        case .yellow: return "circle.fill"
        case .green: return "circle.fill"
        case .blue: return "circle.fill"
        case .pink: return "circle.fill"
        case .orange: return "circle.fill"
        case .purple: return "circle.fill"
        }
    }
}