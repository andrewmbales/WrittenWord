//
//  DebugConfig.swift
//  WrittenWord
//
//  Created by Andrew Bales on 2/6/26.
//


//
//  DebugConfig.swift
//  WrittenWord
//
//  Centralized debug configuration for gating debug prints
//

import Foundation

struct DebugConfig {
    /// Master switch for all debug output
    /// Set to `false` before release builds
    static let isDebugMode = true
    
    /// Specific debug categories - can be toggled independently
    struct Categories {
        static let viewLifecycle = true      // View creation, updates, lifecycle
        static let textRendering = true      // Text view rendering, line spacing
        static let dataLoading = true        // Database seeding, data fetch
        static let userInteraction = true    // Touch events, selections
        static let settings = true           // Settings changes
        static let annotations = true        // Drawing, highlighting
        static let search = true             // Search and filtering
    }
    
    /// Convenience print functions
    static func log(_ category: String, _ items: Any..., separator: String = " ", terminator: String = "\n") {
        guard isDebugMode else { return }
        
        let shouldPrint: Bool = {
            switch category {
            case "lifecycle": return Categories.viewLifecycle
            case "rendering": return Categories.textRendering
            case "data": return Categories.dataLoading
            case "interaction": return Categories.userInteraction
            case "settings": return Categories.settings
            case "annotations": return Categories.annotations
            case "search": return Categories.search
            default: return true  // Unknown categories always print if debug mode is on
            }
        }()
        
        guard shouldPrint else { return }
        
        let message = items.map { String(describing: $0) }.joined(separator: separator)
        print("[\(category.uppercased())] \(message)", terminator: terminator)
    }
}

/// Convenience global debug print function
func debugLog(_ category: String = "DEBUG", _ items: Any..., separator: String = " ") {
    DebugConfig.log(category, items, separator: separator)
}