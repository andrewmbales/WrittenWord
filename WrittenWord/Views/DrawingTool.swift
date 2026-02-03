import Foundation

/// A tool selection for the PencilKit canvas.
/// Matches the cases used in FullPageAnnotationCanvas.
public enum DrawingTool: Equatable {
    case pen
    case highlighter
    case eraser
    case lasso
    case none
}
