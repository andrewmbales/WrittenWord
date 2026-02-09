//
//  HighlightPalette.swift
//  WrittenWord
//
//  Color selection palette for highlighting text.
//  Supports two styles: Horizontal Row and Compact Popover.
//

import SwiftUI

// MARK: - Shared Color Swatch Button

private struct ColorSwatch: View {
    let highlightColor: HighlightColor
    let isSelected: Bool
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(highlightColor.swatchColor)
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                )
                .overlay(
                    isSelected
                        ? Image(systemName: "checkmark")
                            .font(.system(size: size * 0.35, weight: .bold))
                            .foregroundColor(.white)
                        : nil
                )
                .shadow(color: highlightColor.swatchColor.opacity(isSelected ? 0.5 : 0.2), radius: isSelected ? 4 : 2)
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44) // Minimum touch target
    }
}

// MARK: - Remove Highlight Swatch

private struct RemoveHighlightSwatch: View {
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
                    )
                Image(systemName: "xmark")
                    .font(.system(size: size * 0.35, weight: .bold))
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
    }
}

// MARK: - Option A: Horizontal Row Palette

struct HorizontalHighlightPalette: View {
    @Binding var selectedColor: HighlightColor
    let onHighlight: (HighlightColor) -> Void
    let onRemove: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Text("Highlight:")
                .font(.subheadline)
                .fontWeight(.medium)

            HStack(spacing: 8) {
                // Remove highlight swatch (far left)
                RemoveHighlightSwatch(size: 36, action: onRemove)

                ForEach(HighlightColor.allCases, id: \.self) { color in
                    ColorSwatch(
                        highlightColor: color,
                        isSelected: selectedColor == color,
                        size: 36,
                        action: {
                            selectedColor = color
                            onHighlight(color)
                        }
                    )
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
}

// MARK: - Option B: Compact Popover Palette

struct CompactPopoverPalette: View {
    @Binding var selectedColor: HighlightColor
    let onHighlight: (HighlightColor) -> Void
    let onRemove: () -> Void
    let onDismiss: () -> Void

    private let columns = [
        GridItem(.fixed(52), spacing: 8),
        GridItem(.fixed(52), spacing: 8),
        GridItem(.fixed(52), spacing: 8)
    ]

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("Highlight")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }

            // Color grid with remove swatch first
            LazyVGrid(columns: columns, spacing: 8) {
                // Remove highlight swatch (far left, before colors)
                RemoveHighlightSwatch(size: 44, action: onRemove)

                ForEach(HighlightColor.allCases, id: \.self) { color in
                    ColorSwatch(
                        highlightColor: color,
                        isSelected: selectedColor == color,
                        size: 44,
                        action: {
                            selectedColor = color
                            onHighlight(color)
                        }
                    )
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 12, y: 4)
        )
        .frame(width: 200)
    }
}

// MARK: - Unified HighlightPalette (reads user preference)

struct HighlightPalette: View {
    @Binding var selectedColor: HighlightColor
    let onHighlight: (HighlightColor) -> Void
    let onRemove: () -> Void
    let onDismiss: () -> Void

    @AppStorage("paletteStyle") private var paletteStyle: PaletteStyle = .horizontal

    var body: some View {
        switch paletteStyle {
        case .horizontal:
            HorizontalHighlightPalette(
                selectedColor: $selectedColor,
                onHighlight: onHighlight,
                onRemove: onRemove,
                onDismiss: onDismiss
            )
        case .popover:
            CompactPopoverPalette(
                selectedColor: $selectedColor,
                onHighlight: onHighlight,
                onRemove: onRemove,
                onDismiss: onDismiss
            )
        }
    }
}

// MARK: - Previews

#Preview("Horizontal Row") {
    VStack {
        HorizontalHighlightPalette(
            selectedColor: .constant(.yellow),
            onHighlight: { _ in },
            onRemove: { },
            onDismiss: { }
        )
        Spacer()
    }
}

#Preview("Compact Popover") {
    ZStack {
        Color(.systemBackground).ignoresSafeArea()
        CompactPopoverPalette(
            selectedColor: .constant(.blue),
            onHighlight: { _ in },
            onRemove: { },
            onDismiss: { }
        )
    }
}
