//
//  Color+Hex.swift
//  WrittenWord
//
//  Color extensions for hex string conversion
//

import SwiftUI

extension Color {
    /// Convert Color to hex string
    func toHex() -> String {
        let components = UIColor(self).cgColor.components ?? [0, 0, 0, 0]
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
    
    /// Initialize Color from hex string
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

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        // Test hex to color
        Group {
            Color(hex: "#FF0000")
            Color(hex: "#00FF00")
            Color(hex: "#0000FF")
            Color(hex: "#FFD700")
        }
        .frame(height: 50)
        
        // Test color to hex
        Text("Red hex: \(Color.red.toHex())")
        Text("Blue hex: \(Color.blue.toHex())")
        Text("Green hex: \(Color.green.toHex())")
    }
    .padding()
}