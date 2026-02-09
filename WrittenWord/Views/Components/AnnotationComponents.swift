//
//  AnnotationComponents.swift
//  WrittenWord
//
//  FIXED: Better annotation canvas that doesn't interfere with scrolling
//  UPDATED: Eraser type dropdown, drawing sync via delegate
//

import SwiftUI
import PencilKit

// MARK: - Annotation Toolbar
struct AnnotationToolbar: View {
    @Binding var selectedTool: AnnotationTool
    @Binding var selectedColor: Color
    @Binding var penWidth: CGFloat
    @Binding var eraserType: EraserType
    @Binding var showingColorPicker: Bool
    let onUndo: () -> Void
    let onRedo: () -> Void

    private let predefinedColors: [Color] = [
        .black, .gray, .red, .orange, .yellow,
        .green, .blue, .purple, .brown, .pink
    ]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                // Undo / Redo
                undoRedoButtons

                Divider().frame(height: 40)

                // Tool selection
                toolButtons

                Divider().frame(height: 40)

                // Color palette
                colorButtons

                Divider().frame(height: 40)

                // Width slider (when applicable)
                if shouldShowWidthSlider {
                    widthSlider
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }

    private var undoRedoButtons: some View {
        HStack(spacing: 4) {
            Button(action: onUndo) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .foregroundColor(.primary)

            Button(action: onRedo) {
                Image(systemName: "arrow.uturn.forward")
                    .font(.title3)
                    .frame(width: 44, height: 44)
            }
            .foregroundColor(.primary)
        }
    }

    private var toolButtons: some View {
        ForEach(AnnotationTool.allCases, id: \.self) { tool in
            if tool == .eraser {
                eraserButton
            } else {
                Button {
                    selectedTool = tool
                } label: {
                    Image(systemName: tool.icon)
                        .font(.title3)
                        .frame(width: 44, height: 44)
                        .background(selectedTool == tool ? Color.blue.opacity(0.2) : Color.clear)
                        .cornerRadius(8)
                }
                .foregroundColor(selectedTool == tool ? .blue : .primary)
            }
        }
    }

    /// Eraser button: tap to select eraser, long-press to choose type
    private var eraserButton: some View {
        Menu {
            Button {
                eraserType = .partial
                selectedTool = .eraser
            } label: {
                Label("Partial Eraser", systemImage: "eraser")
                if eraserType == .partial {
                    Image(systemName: "checkmark")
                }
            }
            Button {
                eraserType = .object
                selectedTool = .eraser
            } label: {
                Label("Object Eraser", systemImage: "eraser.line.dashed")
                if eraserType == .object {
                    Image(systemName: "checkmark")
                }
            }
        } label: {
            Image(systemName: AnnotationTool.eraser.icon)
                .font(.title3)
                .frame(width: 44, height: 44)
                .background(selectedTool == .eraser ? Color.blue.opacity(0.2) : Color.clear)
                .cornerRadius(8)
        } primaryAction: {
            selectedTool = .eraser
        }
        .foregroundColor(selectedTool == .eraser ? .blue : .primary)
    }

    private var colorButtons: some View {
        Group {
            ForEach(predefinedColors, id: \.self) { color in
                Button {
                    selectedColor = color
                } label: {
                    Circle()
                        .fill(color)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Circle()
                                .stroke(
                                    selectedColor == color ? Color.blue : Color.gray.opacity(0.3),
                                    lineWidth: 2
                                )
                        )
                }
            }

            // Custom color button
            Button {
                showingColorPicker = true
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            AngularGradient(
                                gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]),
                                center: .center
                            )
                        )
                        .frame(width: 28, height: 28)

                    Image(systemName: "plus")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                }
            }
        }
    }

    private var widthSlider: some View {
        HStack(spacing: 8) {
            Image(systemName: "line.diagonal")
                .font(.caption)
                .foregroundStyle(.secondary)

            Slider(value: $penWidth, in: 1...12)
                .frame(width: 100)
                .tint(.blue)

            Text("\(Int(penWidth))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 25)
        }
    }

    private var shouldShowWidthSlider: Bool {
        selectedTool != .eraser && selectedTool != .lasso && selectedTool != .none
    }
}

// MARK: - Annotation Canvas View (with delegate to sync drawing)
struct AnnotationCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let selectedTool: AnnotationTool
    let selectedColor: Color
    let penWidth: CGFloat
    let eraserType: EraserType
    @Binding var canvasView: PKCanvasView
    var onPencilDoubleTap: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawing = drawing
        canvasView.drawingPolicy = .anyInput  // Allow finger + pencil
        canvasView.delegate = context.coordinator

        // Add Apple Pencil double-tap interaction
        let pencilInteraction = UIPencilInteraction()
        pencilInteraction.delegate = context.coordinator
        canvasView.addInteraction(pencilInteraction)

        updateTool()
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Keep coordinator reference up-to-date
        context.coordinator.parent = self

        // Suppress delegate sync while we programmatically update the drawing
        if uiView.drawing != drawing {
            context.coordinator.suppressDrawingSync = true
            uiView.drawing = drawing
            context.coordinator.suppressDrawingSync = false
        }
        updateTool()
    }

    private func updateTool() {
        let uiColor = UIColor(selectedColor)

        switch selectedTool {
        case .pen:
            canvasView.tool = PKInkingTool(.pen, color: uiColor, width: penWidth)
            canvasView.isUserInteractionEnabled = true
        case .highlighter:
            canvasView.tool = PKInkingTool(.marker, color: uiColor.withAlphaComponent(0.5), width: penWidth * 5)
            canvasView.isUserInteractionEnabled = true
        case .eraser:
            switch eraserType {
            case .partial:
                canvasView.tool = PKEraserTool(.bitmap)
            case .object:
                canvasView.tool = PKEraserTool(.vector)
            }
            canvasView.isUserInteractionEnabled = true
        case .lasso:
            canvasView.tool = PKLassoTool()
            canvasView.isUserInteractionEnabled = true
        case .none:
            canvasView.isUserInteractionEnabled = false
        }

        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
    }

    // MARK: - Coordinator (PKCanvasViewDelegate + UIPencilInteractionDelegate)

    class Coordinator: NSObject, PKCanvasViewDelegate, UIPencilInteractionDelegate {
        var parent: AnnotationCanvasView
        var suppressDrawingSync = false

        init(_ parent: AnnotationCanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !suppressDrawingSync else { return }
            // Sync canvas drawing back to binding so it stays up-to-date
            // This prevents updateUIView from overwriting with a stale drawing
            parent.drawing = canvasView.drawing
        }

        // MARK: - UIPencilInteractionDelegate

        func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
            parent.onPencilDoubleTap?()
        }
    }
}

// MARK: - Preview
#Preview("Annotation Toolbar") {
    VStack {
        AnnotationToolbar(
            selectedTool: .constant(.pen),
            selectedColor: .constant(.black),
            penWidth: .constant(2.0),
            eraserType: .constant(.partial),
            showingColorPicker: .constant(false),
            onUndo: { },
            onRedo: { }
        )
        Spacer()
    }
}

#Preview("Highlight Palette") {
    VStack {
        HighlightPalette(
            selectedColor: .constant(.yellow),
            onHighlight: { color in
                print("Selected color: \(color)")
            },
            onRemove: {
                print("Removed")
            },
            onDismiss: {
                print("Dismissed")
            }
        )
        Spacer()
    }
}
