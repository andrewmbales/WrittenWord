//
//  AnnotationComponents.swift
//  WrittenWord
//
//  Separated annotation UI components for better organization
//

import SwiftUI
import PencilKit

// MARK: - Annotation Toolbar
struct AnnotationToolbar: View {
    @Binding var selectedTool: AnnotationTool
    @Binding var selectedColor: Color
    @Binding var penWidth: CGFloat
    @Binding var showingColorPicker: Bool
    
    private let predefinedColors: [Color] = [
        .black, .gray, .red, .orange, .yellow,
        .green, .blue, .purple, .brown, .pink
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
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
    
    private var toolButtons: some View {
        ForEach(AnnotationTool.allCases, id: \.self) { tool in
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

// MARK: - Highlight Palette
struct HighlightPalette: View {
    @Binding var selectedColor: HighlightColor
    let onHighlight: (HighlightColor) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Text("Highlight:")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            // Color options
            ForEach(HighlightColor.allCases, id: \.self) { color in
                colorButton(for: color)
            }
            
            Spacer()
            
            Button("Cancel", action: onDismiss)
                .font(.subheadline)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private func colorButton(for color: HighlightColor) -> some View {
        Button {
            selectedColor = color
            onHighlight(color)
        } label: {
            Circle()
                .fill(color.color)
                .frame(width: 32, height: 32)
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
        }
    }
}

// MARK: - Annotation Canvas View
struct AnnotationCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let selectedTool: AnnotationTool
    let selectedColor: Color
    let penWidth: CGFloat
    @Binding var canvasView: PKCanvasView
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawing = drawing
        canvasView.delegate = context.coordinator
        canvasView.alwaysBounceVertical = false  // Changed to false
        canvasView.alwaysBounceHorizontal = false
        
        // Start with drawing disabled
        canvasView.drawingPolicy = .pencilOnly
        canvasView.isUserInteractionEnabled = false
        
        updateTool()
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
        updateTool()
        updateInteractionState()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func updateTool() {
        let uiColor = UIColor(selectedColor)
        
        switch selectedTool {
        case .none:
            // Explicitly set no tool
            break
        case .pen:
            canvasView.tool = PKInkingTool(.pen, color: uiColor, width: penWidth)
        case .highlighter:
            canvasView.tool = PKInkingTool(
                .marker,
                color: uiColor.withAlphaComponent(0.3),
                width: penWidth * 3
            )
        case .eraser:
            canvasView.tool = PKEraserTool(.vector)
        case .lasso:
            canvasView.tool = PKLassoTool()
        }
    }
    
    private func updateInteractionState() {
        // Enable/disable based on tool selection
        if selectedTool == .none {
            canvasView.isUserInteractionEnabled = false
            canvasView.drawingPolicy = .pencilOnly
        } else {
            canvasView.isUserInteractionEnabled = true
            canvasView.drawingPolicy = .anyInput  // Allow finger and pencil
        }
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: AnnotationCanvasView
        
        init(_ parent: AnnotationCanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
}

// MARK: - Full Page Annotation Canvas
struct FullPageAnnotationCanvas: View {
    @Bindable var note: Note
    let selectedTool: AnnotationTool
    let selectedColor: Color
    let penWidth: CGFloat
    @Binding var canvasView: PKCanvasView
    
    var body: some View {
        AnnotationCanvasView(
            drawing: Binding(
                get: { note.drawing },
                set: { note.drawing = $0 }
            ),
            selectedTool: selectedTool,
            selectedColor: selectedColor,
            penWidth: penWidth,
            canvasView: $canvasView
        )
        .background(Color.clear)
        // Only enable interaction when a tool is selected (not .none)
        .allowsHitTesting(selectedTool != .none)
    }
}

// MARK: - Preview
#Preview("Annotation Toolbar") {
    AnnotationToolbar(
        selectedTool: .constant(.pen),
        selectedColor: .constant(.black),
        penWidth: .constant(2.0),
        showingColorPicker: .constant(false)
    )
}

#Preview("Highlight Palette") {
    HighlightPalette(
        selectedColor: .constant(.yellow),
        onHighlight: { _ in },
        onDismiss: {}
    )
}
