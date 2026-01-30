//
//  HighlightPalette.swift
//  WrittenWord
//
//  Color selection palette for highlighting text
//

import SwiftUI

struct HighlightPalette: View {
    @Binding var selectedColor: HighlightColor
    let onHighlight: (HighlightColor) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Text("Highlight:")
                .font(.subheadline)
                .fontWeight(.medium)
            
            // Color options
            HStack(spacing: 12) {
                ForEach(HighlightColor.allCases, id: \.self) { color in
                    colorButton(for: color)
                }
            }
            
            Spacer()
            
            Button("Cancel", action: onDismiss)
                .font(.subheadline)
                .foregroundStyle(.gray)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }
    
    private func colorButton(for color: HighlightColor) -> some View {
        Button {
            selectedColor = color
            onHighlight(color)
        } label: {
            Circle()
                .fill(color.color)
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                )
                .overlay(
                    selectedColor == color ?
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    : nil
                )
                .shadow(
                    color: color.color.opacity(0.3),
                    radius: selectedColor == color ? 4 : 0
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    VStack {
        HighlightPalette(
            selectedColor: .constant(.yellow),
            onHighlight: { color in
                print("Selected: \(color.rawValue)")
            },
            onDismiss: {
                print("Dismissed")
            }
        )
        
        Spacer()
    }
}