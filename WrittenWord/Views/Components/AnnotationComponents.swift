//
//  AnnotationComponents_FIXED.swift
//  WrittenWord
//
//  FIXED: Better annotation canvas that doesn't interfere with scrolling
//

import SwiftUI
import PencilKit

// MARK: - Annotation Toolbar (unchanged, kept for reference)
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

// MARK: - FIXED Annotation Canvas View
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
        
        // CRITICAL FIX: Disable bouncing to prevent scroll conflicts
        canvasView.alwaysBounceVertical = false
        canvasView.alwaysBounceHorizontal = false
        
        // Start with interaction disabled
        canvasView.isUserInteractionEnabled = false
        canvasView.drawingPolicy = .pencilOnly
        
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
            // No tool selected
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
        // CRITICAL FIX: Only enable when a tool is selected
        if selectedTool == .none {
            canvasView.isUserInteractionEnabled = false
            canvasView.drawingPolicy = .pencilOnly
        } else {
            canvasView.isUserInteractionEnabled = true
            canvasView.drawingPolicy = .anyInput
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

// MARK: - Preview
#Preview("Annotation Toolbar") {
    VStack {
        AnnotationToolbar(
            selectedTool: .constant(.pen),
            selectedColor: .constant(.black),
            penWidth: .constant(2.0),
            showingColorPicker: .constant(false)
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
            onDismiss: {
                print("Dismissed")
            }
        )
        Spacer()
    }
}