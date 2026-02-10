//
//  ChapterView.swift
//  WrittenWord
//
//  OPTIMIZED: Better performance, margin support, and fixed bottom sheet presentation
//

import SwiftUI
import SwiftData
import PencilKit

struct ChapterView: View {
    let chapter: Chapter
    @State private var viewModel: ChapterViewModel?
    @Environment(\.modelContext) private var modelContext

    // Settings
    @AppStorage("fontSize") private var fontSize: Double = 16.0
    @AppStorage("lineSpacing") private var lineSpacing: Double = 6.0
    @AppStorage("colorTheme") private var colorTheme: ColorTheme = .system
    @AppStorage("fontFamily") private var fontFamily: FontFamily = .system
    
    // Margin settings
    @AppStorage("leftMargin") private var leftMargin: Double = 40.0
    @AppStorage("rightMargin") private var rightMargin: Double = 40.0

    // Palette style
    @AppStorage("paletteStyle") private var paletteStyle: PaletteStyle = .horizontal

    // Interlinear persisted toggle
    @AppStorage("showInterlinear") private var showInterlinear: Bool = false

    // Apple Pencil double-tap toggle setting
    @AppStorage("pencilDoubleTapEnabled") private var pencilDoubleTapEnabled: Bool = true

    // Pinch-to-zoom state
    @State private var pinchBaseFontSize: Double?

    let onChapterChange: (Chapter) -> Void
    
    // MARK: - Initialization
    init(chapter: Chapter, onChapterChange: @escaping (Chapter) -> Void) {
        self.chapter = chapter
        self.onChapterChange = onChapterChange
    }
    
    // MARK: - Body
    var body: some View {
        Group {
            if let vm = viewModel {
                chapterContentView(vm)
            } else {
                ProgressView("Loading chapter...")
            }
        }
        .task(id: chapter.id) {
            if viewModel == nil || viewModel?.chapter.id != chapter.id {
                #if DEBUG
                print("🔄 ChapterView: Creating viewModel for \(chapter.reference)")
                #endif
                viewModel = ChapterViewModel(chapter: chapter, modelContext: modelContext)
                viewModel?.showInterlinear = showInterlinear
                await viewModel?.loadChapterNote()
            }
        }
    }
    
    @ViewBuilder
    private func chapterContentView(_ vm: ChapterViewModel) -> some View {
        @Bindable var viewModel = vm
        
        ZStack {
            // Background
            colorTheme.backgroundColor.ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Annotation toolbar
                if viewModel.showAnnotations {
                    AnnotationToolbar(
                        selectedTool: $viewModel.selectedTool,
                        selectedColor: $viewModel.selectedColor,
                        penWidth: $viewModel.penWidth,
                        eraserType: $viewModel.eraserType,
                        showingColorPicker: $viewModel.showingColorPicker,
                        onUndo: { vm.undoAnnotation() },
                        onRedo: { vm.redoAnnotation() }
                    )
                    Divider()
                }
                
                // Highlight palette (horizontal style renders inline)
                if viewModel.showHighlightMenu && paletteStyle == .horizontal {
                    HorizontalHighlightPalette(
                        selectedColor: $viewModel.selectedHighlightColor,
                        onHighlight: viewModel.createHighlight,
                        onRemove: viewModel.removeHighlightAtSelection,
                        onDismiss: {
                            viewModel.showHighlightMenu = false
                            viewModel.selectedRange = nil
                            viewModel.selectedText = ""
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    Divider()
                }

                // Chapter content with popover overlay
                ZStack(alignment: .top) {
                    chapterContent(vm)

                    // Highlight palette (popover style floats over content)
                    if viewModel.showHighlightMenu && paletteStyle == .popover {
                        CompactPopoverPalette(
                            selectedColor: $viewModel.selectedHighlightColor,
                            onHighlight: viewModel.createHighlight,
                            onRemove: viewModel.removeHighlightAtSelection,
                            onDismiss: {
                                viewModel.showHighlightMenu = false
                                viewModel.selectedRange = nil
                                viewModel.selectedText = ""
                            }
                        )
                        .padding(.top, 16)
                        .transition(.scale(scale: 0.85).combined(with: .opacity))
                        .zIndex(50)
                    }
                }
            }
            
            // FIXED: Bottom sheet for interlinear lookup (outside ScrollView for proper presentation)
            if viewModel.showInterlinearLookup, let word = viewModel.selectedWord {
                ZStack {
                    // Dimmed background
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                viewModel.showInterlinearLookup = false
                                viewModel.selectedWord = nil
                            }
                        }
                    
                    // Bottom sheet
                    VStack {
                        Spacer()
                        
                        InterlinearBottomSheet(
                            word: word,
                            onDismiss: {
                                withAnimation {
                                    viewModel.showInterlinearLookup = false
                                    viewModel.selectedWord = nil
                                }
                            }
                        )
                    }
                }
                .transition(.opacity)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showInterlinearLookup)
                .zIndex(100) // Ensure bottom sheet appears above everything
            }
        }
        .navigationTitle("\(viewModel.chapter.book?.name ?? "") \(viewModel.chapter.number)")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            toolbarContent(vm)
        }
        .sheet(isPresented: vm.bindingForShowingDrawing()) {
            NavigationStack {
                FullPageDrawingView(chapter: vm.chapter)
            }
            .preferredColorScheme(colorTheme.preferredColorScheme)
        }
        .sheet(isPresented: vm.bindingForShowingColorPicker()) {
            ColorPickerSheet(selectedColor: vm.bindingForSelectedColor())
                .preferredColorScheme(colorTheme.preferredColorScheme)
        }
        .searchable(text: vm.bindingForSearchText(), prompt: "Search verses")
        .alert("Remove All Highlights", isPresented: Binding(
            get: { vm.showRemoveHighlightsConfirmation },
            set: { vm.showRemoveHighlightsConfirmation = $0 }
        )) {
            Button("Cancel", role: .cancel) { }
            Button("Remove All", role: .destructive) {
                vm.removeAllHighlightsInChapter()
            }
        } message: {
            Text("Are you sure you want to remove all highlights in this chapter? This cannot be undone.")
        }
    }
    
    @ViewBuilder
    private func chapterContent(_ vm: ChapterViewModel) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    // Previous chapter button at top
                    if let previousChapter = vm.previousChapter, vm.searchText.isEmpty {
                        Button {
                            onChapterChange(previousChapter)
                        } label: {
                            HStack {
                                Image(systemName: "arrow.left")
                                Text("Back to \(previousChapter.book?.name ?? "") \(previousChapter.number)")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }

                    if showInterlinear {
                        // Interlinear mode — margins match regular text view
                        VStack(spacing: 0) {
                            ForEach(vm.filteredVerses, id: \.id) { verse in
                                InterlinearVerseView(
                                    verse: verse,
                                    fontSize: fontSize,
                                    fontFamily: fontFamily,
                                    colorTheme: colorTheme,
                                    onWordTapped: { word in
                                        vm.selectedWord = word
                                        vm.showInterlinearLookup = true
                                    }
                                )
                            }
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 20)
                    } else {
                        // Regular text mode
                        WordSelectableChapterTextView(
                            verses: vm.filteredVerses,
                            highlights: vm.filteredVerses.flatMap { verse in
                                vm.highlightsForVerse(verse.id)
                            },
                            fontSize: fontSize,
                            fontFamily: fontFamily,
                            lineSpacing: lineSpacing,
                            colorTheme: colorTheme,
                            leftMargin: leftMargin,
                            rightMargin: rightMargin,
                            onTextSelected: { verse, range, text in
                                vm.selectTextForHighlight(verse: verse, range: range, text: text)
                            },
                            onVerseTapped: { verse in
                                vm.selectVerseForHighlight(verse: verse)
                            },
                            selectedVerseId: vm.selectedVerse?.id,
                            selectionRange: vm.selectedRange
                        )
                    }

                    // Continue to next chapter button
                    if let nextChapter = vm.nextChapter, vm.searchText.isEmpty {
                        Button {
                            onChapterChange(nextChapter)
                        } label: {
                            HStack {
                                Text("Continue to \(nextChapter.book?.name ?? "") \(nextChapter.number)")
                                Image(systemName: "arrow.right")
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
                // Annotation canvas — overlaid on content so it scrolls with the text.
                // Drawings stay positioned relative to verses (e.g., a note next to John 1:5
                // remains next to John 1:5 when scrolling).
                .overlay {
                    if vm.showAnnotations {
                        AnnotationCanvasView(
                            drawing: vm.bindingForChapterNoteDrawing(),
                            selectedTool: vm.selectedTool,
                            selectedColor: vm.selectedColor,
                            penWidth: vm.penWidth,
                            eraserType: vm.eraserType,
                            canvasView: vm.bindingForCanvasView(),
                            onPencilDoubleTap: {
                                guard pencilDoubleTapEnabled else { return }
                                withAnimation {
                                    vm.toggleCurrentTool()
                                }
                            }
                        )
                        .allowsHitTesting(vm.selectedTool != .none)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .simultaneousGesture(
                MagnificationGesture()
                    .onChanged { scale in
                        if pinchBaseFontSize == nil {
                            pinchBaseFontSize = fontSize
                        }
                        let newSize = (pinchBaseFontSize ?? fontSize) * scale
                        fontSize = min(max(newSize, 12), 36)
                    }
                    .onEnded { _ in
                        pinchBaseFontSize = nil
                    }
            )
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent(_ vm: ChapterViewModel) -> some ToolbarContent {
        // Annotation and interlinear toggle buttons
        ToolbarItem(placement: .navigationBarLeading) {
            HStack(spacing: 12) {
                Button {
                    withAnimation {
                        vm.toggleAnnotations()
                    }
                } label: {
                    Image(systemName: vm.showAnnotations ?
                        "pencil.tip.crop.circle.fill" : "pencil.tip.crop.circle")
                        .foregroundColor(vm.showAnnotations ? .blue : .primary)
                }

                // Interlinear toggle button (א for OT, α for NT)
                Button {
                    withAnimation {
                        showInterlinear.toggle()
                        vm.showInterlinear = showInterlinear
                    }
                } label: {
                    Text(vm.interlinearCharacter)
                        .font(.system(size: 18, weight: showInterlinear ? .bold : .regular))
                        .foregroundColor(showInterlinear ? .green : .primary)
                }
                .help(vm.interlinearLanguage)
            }
        }
                
        // Navigation and menu
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 8) {
                // Previous chapter
                if let previous = vm.previousChapter {
                    Button {
                        onChapterChange(previous)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
                
                // Menu with additional options
                Menu {
                    Button {
                        vm.selectedVerse = nil
                        vm.showingDrawing = true
                    } label: {
                        Label("Full Page Note", systemImage: "note.text.badge.plus")
                    }
                    
                    Button(action: vm.bookmarkChapter) {
                        Label("Bookmark Chapter", systemImage: "bookmark.fill")
                    }
                    
                    Divider()
                    
                    Button {
                        withAnimation {
                            vm.toggleAnnotations()
                        }
                    } label: {
                        Label(
                            vm.showAnnotations ? "Hide Annotations" : "Show Annotations",
                            systemImage: vm.showAnnotations ?
                                "pencil.tip.crop.circle.fill" : "pencil.tip.crop.circle"
                        )
                    }

                    if vm.chapterHighlightCount > 0 {
                        Divider()

                        Button(role: .destructive) {
                            vm.showRemoveHighlightsConfirmation = true
                        } label: {
                            Label("Remove All Highlights", systemImage: "highlighter")
                        }
                    }

                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                
                // Next chapter
                if let next = vm.nextChapter {
                    Button {
                        onChapterChange(next)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
            }
        }
    }
}

/*
#Preview {
    NavigationStack {
        ChapterView(chapter: Chapter(
            number: 1,
            reference: "Genesis 1",
            book: Book(
                name: "Genesis",
                abbrev: "Gen",
                order: 1,
                testament: "OT"
            )
        )) { _ in }
    }
}
*/
