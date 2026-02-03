import SwiftUI
import PencilKit

struct FullPageAnnotationCanvas: UIViewRepresentable {
    let note: Note
    let selectedTool: DrawingTool
    let selectedColor: Color
    let penWidth: CGFloat
    @Binding var canvasView: PKCanvasView

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawingPolicy = .anyInput
        return canvasView
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        switch selectedTool {
        case .pen:
            uiView.tool = PKInkingTool(.pen, color: UIColor(selectedColor), width: penWidth)
            uiView.isUserInteractionEnabled = true
        case .highlighter:
            uiView.tool = PKInkingTool(.marker, color: UIColor(selectedColor).withAlphaComponent(0.5), width: penWidth * 1.5)
            uiView.isUserInteractionEnabled = true
        case .eraser:
            uiView.tool = PKEraserTool(.vector)
            uiView.isUserInteractionEnabled = true
        case .none:
            uiView.tool = PKInkingTool(.pen, color: .clear, width: 0.1)
            uiView.isUserInteractionEnabled = false
        }
        uiView.isOpaque = false
        uiView.backgroundColor = .clear
    }
}

extension UIColor {
    convenience init(_ color: Color) {
        self.init(color)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var canvasView = PKCanvasView()
        @State private var tool: DrawingTool = .pen
        @State private var color: Color = .blue
        @State private var width: CGFloat = 5.0
        let note = Note()

        var body: some View {
            FullPageAnnotationCanvas(
                note: note,
                selectedTool: tool,
                selectedColor: color,
                penWidth: width,
                canvasView: $canvasView
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.gray.opacity(0.1))
        }
    }
    PreviewWrapper()
}
