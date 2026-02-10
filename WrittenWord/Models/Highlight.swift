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
        // Direct hex conversion to avoid extension ambiguity
        let uiColor = UIColor(color)
        let components = uiColor.cgColor.components ?? [0, 0, 0, 0]
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        self.color = String(format: "#%02X%02X%02X", r, g, b)
        self.text = text
        self.createdAt = Date()
        self.verse = verse
    }
    
    var highlightColor: Color {
        // Direct hex parsing to avoid extension ambiguity
        var hexSanitized = color.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            return .yellow
        }
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        return Color(red: r, green: g, blue: b)
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

    /// The swatch color shown in the palette UI (full saturation)
    var swatchColor: Color {
        switch self {
        case .yellow: return Color(red: 1.0, green: 0.922, blue: 0.231)    // #FFEB3B
        case .green:  return Color(red: 0.545, green: 0.765, blue: 0.290)  // #8BC34A
        case .blue:   return Color(red: 0.129, green: 0.588, blue: 0.953)  // #2196F3
        case .pink:   return Color(red: 0.914, green: 0.118, blue: 0.388)  // #E91E63
        case .purple: return Color(red: 0.612, green: 0.153, blue: 0.690)  // #9C27B0
        case .orange: return Color(red: 1.0, green: 0.596, blue: 0.0)      // #FF9800
        }
    }

    /// The color applied to highlighted text (lower opacity for readability)
    var color: Color {
        swatchColor.opacity(0.4)
    }
}

// MARK: - Palette Style
enum PaletteStyle: String, CaseIterable {
    case horizontal = "Horizontal Row"
    case popover = "Compact Popover"

    var description: String {
        switch self {
        case .horizontal: return "Color circles in a row, Apple Books style"
        case .popover: return "Floating 3x2 grid near your selection"
        }
    }

    var icon: String {
        switch self {
        case .horizontal: return "rectangle.split.1x2"
        case .popover: return "rectangle.split.2x2"
        }
    }
}