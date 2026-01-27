import SwiftUI

struct ChapterReaderView: View {
    @ObservedObject var vm: ChapterViewModel

    var body: some View {
        optimizedChapterContent(vm)
    }

    @ViewBuilder
    func optimizedChapterContent(_ vm: ChapterViewModel) -> some View {
        ZStack {
            chapterContentView(vm)
            AnnotationCanvasView(viewModel: vm)
                .allowsHitTesting(vm.selectedTool != .none && vm.showHighlightMenu == false && vm.showingColorPicker == false && vm.searchText.isEmpty)
        }
    }

    @ViewBuilder
    func chapterContentView(_ vm: ChapterViewModel) -> some View {
        ScrollView {
            Text(vm.chapterText)
                .padding()
        }
        .onDisappear {
            saveAnnotations(viewModel: vm)
            vm.showingDrawing = false
            vm.showingColorPicker = false
            vm.showingBookmarkSheet = false
            vm.showHighlightMenu = false
            vm.selectedTool = .none
        }
    }

    func saveAnnotations(viewModel: ChapterViewModel) {
        // Saving logic here
    }
}

struct AnnotationCanvasView: View {
    @ObservedObject var viewModel: ChapterViewModel

    var body: some View {
        // Drawing canvas UI here
        Rectangle()
            .stroke(Color.red, lineWidth: 2)
    }
}

class ChapterViewModel: ObservableObject {
    @Published var chapterText: String = ""
    @Published var selectedTool: Tool = .none
    @Published var showHighlightMenu: Bool = false
    @Published var showingColorPicker: Bool = false
    @Published var showingDrawing: Bool = false
    @Published var showingBookmarkSheet: Bool = false
    @Published var searchText: String = ""

    enum Tool {
        case none, pen, eraser
    }
}
