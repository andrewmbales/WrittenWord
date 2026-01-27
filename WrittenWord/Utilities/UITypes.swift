//
//  UITypes.swift
//  WrittenWord
//
//  Shared UI types and enums used across multiple views
//

import SwiftUI

// MARK: - Note Position
enum NotePosition: String, CaseIterable {
    case left = "left"
    case right = "right"
    
    var displayName: String {
        switch self {
        case .left: return "Left"
        case .right: return "Right"
        }
    }
}

enum AnnotationTool: String, CaseIterable {
    case none
    case pen
    case highlighter
    case eraser
    case lasso

    var icon: String {
        switch self {
        case .none: return "nosign"
        case .pen: return "pencil"
        case .highlighter: return "highlighter"
        case .eraser: return "eraser.fill"
        case .lasso: return "lasso"
        }
    }
}

// MARK: - Color Theme
enum ColorTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    case sepia = "Sepia"
    case sand = "Sand"
    
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .system: return "sparkles"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .sepia: return "book.fill"
        case .sand: return "beach.umbrella.fill"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .system: return Color(.systemBackground)
        case .light: return Color.white
        case .dark: return Color.black
        case .sepia: return Color(red: 0.95, green: 0.91, blue: 0.82)
        case .sand: return Color(red: 0.98, green: 0.95, blue: 0.88)
        }
    }
    
    var textColor: Color {
        switch self {
        case .system: return Color(.label)
        case .light: return Color.black
        case .dark: return Color.white
        case .sepia: return Color(red: 0.2, green: 0.15, blue: 0.1)
        case .sand: return Color(red: 0.3, green: 0.25, blue: 0.2)
        }
    }
}

// MARK: - Font Family
enum FontFamily: String, CaseIterable {
    case system = "System"
    case serif = "Serif"
    case rounded = "Rounded"
    case monospaced = "Monospaced"
    
    var displayName: String { rawValue }
    
    func font(size: CGFloat) -> Font {
        switch self {
        case .system: return .system(size: size)
        case .serif: return .custom("Georgia", size: size)
        case .rounded: return .system(size: size, design: .rounded)
        case .monospaced: return .system(size: size, design: .monospaced)
        }
    }
}