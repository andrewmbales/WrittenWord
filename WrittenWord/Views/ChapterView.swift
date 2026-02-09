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
    
    // NEW: Margin settings
    @AppStorage("leftMargin") private var leftMargin: Double = 40.0
    @AppStorage("rightMargin") private var rightMargin: Double = 40.0
    
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
                        showingColorPicker: $viewModel.showingColorPicker
                    )
                    Divider()
                }
                
                // Highlight palette
                if viewModel.showHighlightMenu {
                    HighlightPalette(
                        selectedColor: $viewModel.selectedHighlightColor,
                        onHighlight: viewModel.createHighlight,
                        onDismiss: {
                            viewModel.showHighlightMenu = false
                            viewModel.selectedRange = nil
                            viewModel.selectedText = ""
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    Divider()
                }
                
                // Chapter content
                chapterContent(vm)
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent(vm)
        }
        .sheet(isPresented: vm.bindingForShowingDrawing()) {
            FullPageDrawingView(note: vm.chapterNote)
        }
        .sheet(isPresented: vm.bindingForShowingColorPicker()) {
            ColorPickerSheet(selectedColor: vm.bindingForSelectedColor())
        }
        .searchable(text: vm.bindingForSearchText(), prompt: "Search verses")
    }
    
    @ViewBuilder
    private func chapterContent(_ vm: ChapterViewModel) -> some View {
        ZStack {
            // Text content (bottom layer)
            ScrollViewReader { proxy in
                ScrollView {
                    if vm.showInterlinear {
                        // NEW: Interlinear mode
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
                        .padding(.vertical)
                    } else {
                        // Existing: Regular text mode
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
                            }
                        )
                        .padding(.vertical)
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
                .scrollIndicators(.hidden)
            }
            
            // Annotation canvas overlay (top layer) - ONLY when annotations enabled
            if vm.showAnnotations {
                GeometryReader { geometry in
                    AnnotationCanvasView(
                        drawing: vm.bindingForChapterNoteDrawing(),
                        selectedTool: vm.selectedTool,
                        selectedColor: vm.selectedColor,
                        penWidth: vm.penWidth,
                        canvasView: vm.bindingForCanvasView()
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .allowsHitTesting(vm.selectedTool != .none)  // CRITICAL
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent(_ vm: ChapterViewModel) -> some ToolbarContent {
        // Annotation toggle button
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                withAnimation {
                    vm.toggleAnnotations()
                }
            } label: {
                Image(systemName: vm.showAnnotations ?
                    "pencil.tip.crop.circle.fill" : "pencil.tip.crop.circle")
                    .foregroundColor(vm.showAnnotations ? .blue : .primary)
            }
            
            // NEW: Interlinear toggle button
            Button {
                withAnimation {
                    vm.showInterlinear.toggle()
                }
            } label: {
                Image(systemName: vm.showInterlinear ?
                    "\(vm.interlinearIcon).fill" : vm.interlinearIcon)
                    .foregroundColor(vm.showInterlinear ? .green : .primary)
            }
            .help(vm.interlinearLanguage) // Shows tooltip on hover (iPad/Mac)
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
                    
                    // Button in menu for toggling interlinear
                    Button {
                        withAnimation {
                            vm.showInterlinear.toggle()
                        }
                    } label: {
                        Label(
                            vm.showInterlinear ? "Hide \(vm.interlinearLanguage)" : "Show \(vm.interlinearLanguage)",
                            systemImage: vm.interlinearIcon
                        )
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
