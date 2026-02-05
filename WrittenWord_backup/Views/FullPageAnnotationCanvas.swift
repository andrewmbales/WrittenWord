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
        case .lasso:
            uiView.tool = PKEraserTool(.bitmap)
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
        // Convert SwiftUI Color to UIColor using color resolution
        // This requires iOS 17+ for the resolve method
        if #available(iOS 17.0, *) {
            let resolved = color.resolve(in: EnvironmentValues())
            self.init(
                red: Double(resolved.red),
                green: Double(resolved.green),
                blue: Double(resolved.blue),
                alpha: Double(resolved.opacity)
            )
        } else {
            // Fallback for iOS 16 and earlier
            // Use a temporary UIHostingController to get the UIColor
            let view = UIHostingController(rootView: Rectangle().foregroundColor(color))
            view.view.layoutIfNeeded()
            if let cgColor = view.view.layer.backgroundColor {
                self.init(cgColor: cgColor)
            } else {
                // Final fallback to black
                self.init(red: 0, green: 0, blue: 0, alpha: 1)
            }
        }
    }
}

struct FullPageAnnotationCanvas_PreviewWrapper: View {
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

#Preview {
    FullPageAnnotationCanvas_PreviewWrapper()
}
