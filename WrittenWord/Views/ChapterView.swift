//
//  ChapterView.swift
//  WrittenWord
//
//  Optimized chapter view with MVVM pattern, line spacing support, and easy annotation access
//
/*
import SwiftUI
import SwiftData
import PencilKit

struct ChapterView: View {
    let chapter: Chapter
    @State private var viewModel: ChapterViewModel?
    @Environment(\.modelContext) private var modelContext

    // Settings - now properly reactive to changes
    @AppStorage("fontSize") private var fontSize: Double = 16.0
    @AppStorage("lineSpacing") private var lineSpacing: Double = 6.0
    @AppStorage("colorTheme") private var colorTheme: ColorTheme = .system
    @AppStorage("fontFamily") private var fontFamily: FontFamily = .system

    // Force recreation counter for settings changes
    @State private var textViewRecreationID = UUID()
    
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
                ProgressView()
            }
        }
        .task(id: chapter.id) {
            // Better lifecycle management - recreates viewModel when chapter changes
            if viewModel == nil || viewModel?.chapter.id != chapter.id {
                debugLog("lifecycle", "🔄 ChapterView: Creating/updating viewModel for chapter \(chapter.number)")
                viewModel = ChapterViewModel(chapter: chapter, modelContext: modelContext)
                await viewModel?.loadChapterNote()
            }
        }
        // Watch for setting changes and force recreation
        .onChange(of: lineSpacing) { _, newValue in
            debugLog("settings", "📏 ChapterView: Line spacing changed to \(newValue), recreating text view")
            textViewRecreationID = UUID()
        }
        .onChange(of: fontSize) { _, newValue in
            debugLog("settings", "🔤 ChapterView: Font size changed to \(newValue), recreating text view")
            textViewRecreationID = UUID()
        }
        .onChange(of: fontFamily) { _, newValue in
            debugLog("settings", "🖋️ ChapterView: Font family changed to \(newValue.rawValue), recreating text view")
            textViewRecreationID = UUID()
        }
        .onChange(of: colorTheme) { _, newValue in
            debugLog("settings", "🎨 ChapterView: Color theme changed to \(newValue.rawValue), recreating text view")
            textViewRecreationID = UUID()
        }
    }
    
    @ViewBuilder
    private func chapterContentView(_ vm: ChapterViewModel) -> some View {
        ZStack {
            colorTheme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Annotation toolbar (shown when annotations enabled)
                if vm.showAnnotations {
                    AnnotationToolbar(
                        selectedTool: vm.bindingForSelectedTool(),
                        selectedColor: vm.bindingForSelectedColor(),
                        penWidth: vm.bindingForPenWidth(),
                        showingColorPicker: vm.bindingForShowingColorPicker()
                    )
                    Divider()
                }
                
                // Highlight palette (shown when text selected)
                if vm.showHighlightMenu {
                    HighlightPalette(
                        selectedColor: vm.bindingForSelectedHighlightColor(),
                        onHighlight: vm.createHighlight,
                        onDismiss: {
                            vm.showHighlightMenu = false
                            vm.selectedRange = nil
                            vm.selectedText = ""
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    Divider()
                }
                
                // Chapter content with overlay
                chapterContent(vm)
            }
        }
        .navigationTitle("\(vm.chapter.book?.name ?? "") \(vm.chapter.number)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            toolbarContent(vm)
        }
        .sheet(isPresented: vm.bindingForShowingDrawing()) {
            FullPageDrawingView(note: vm.chapterNote)
        }
        
        // Commenting out the below references until I can build them out more comprehensively
       /* .sheet(isPresented: vm.bindingForShowingBookmarkSheet()) {
            if let verse = vm.verseToBookmark {
                BookmarkDetailView(verse: verse)
            }
        }
        .sheet(isPresented: vm.bindingForShowInterlinearLookup()) {
            if let word = vm.selectedWord {
                InterlinearWordDetailView(word: word)
            }
        }*/
        .sheet(isPresented: vm.bindingForShowingColorPicker()) {
            ColorPickerSheet(selectedColor: vm.bindingForSelectedColor())
        }
        .searchable(text: vm.bindingForSearchText(), prompt: "Search verses")
    }
    
    @ViewBuilder
    private func chapterContent(_ vm: ChapterViewModel) -> some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView {
                    let _ = debugLog("rendering", "🔧 Building text view with settings: fontSize=\(fontSize), lineSpacing=\(lineSpacing), font=\(fontFamily.rawValue), theme=\(colorTheme.rawValue)")
                    
                    WordSelectableChapterTextView(
                        verses: vm.filteredVerses,
                        highlights: vm.filteredVerses.flatMap { verse in
                            vm.highlightsForVerse(verse.id)
                        },
                        fontSize: fontSize,
                        fontFamily: fontFamily,
                        lineSpacing: lineSpacing,
                        colorTheme: colorTheme,
                        onTextSelected: { verse, range, text in
                            vm.selectTextForHighlight(verse: verse, range: range, text: text)
                        }
                    )
                    .id(textViewRecreationID)
                    .padding(.vertical)
                    
                    if let nextChapter = vm.nextChapter, vm.searchText.isEmpty {
                        Button {
                            onChapterChange(nextChapter)
                        } label: {
                            HStack {
                                Text("Continue to \(nextChapter.book?.name ?? "") \(nextChapter.number)")
                                    .font(.headline)
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                }
                .allowsHitTesting(vm.selectedTool == .none)
            }
            
            // Annotation overlay
            if vm.showAnnotations {
                GeometryReader { geometry in
                    FullPageAnnotationCanvas(
                        note: vm.chapterNote,
                        selectedTool: vm.convertToDrawingTool(),
                        selectedColor: vm.selectedColor,
                        penWidth: vm.penWidth,
                        canvasView: vm.bindingForCanvasView()
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private func toolbarContent(_ viewModel: ChapterViewModel) -> some ToolbarContent {
        // Annotation toggle button (prominent placement)
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                withAnimation {
                    viewModel.toggleAnnotations()
                }
            } label: {
                Image(systemName: viewModel.showAnnotations ? "pencil.tip.crop.circle.fill" : "pencil.tip.crop.circle")
                    .foregroundColor(viewModel.showAnnotations ? .blue : .primary)
            }
        }
        
        // Navigation and menu
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 8) {
                // Previous chapter
                if let previous = viewModel.previousChapter {
                    Button {
                        onChapterChange(previous)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
                
                // Menu with additional options
                Menu {
                    Button {
                        viewModel.selectedVerse = nil
                        viewModel.showingDrawing = true
                    } label: {
                        Label("Full Page Note", systemImage: "note.text.badge.plus")
                    }
                    
                    Button(action: viewModel.bookmarkChapter) {
                        Label("Bookmark Chapter", systemImage: "bookmark.fill")
                    }
                    
                    Divider()
                    
                    // Annotation toggle also in menu (for discoverability)
                    Button {
                        withAnimation {
                            viewModel.toggleAnnotations()
                        }
                    } label: {
                        Label(
                            viewModel.showAnnotations ? "Hide Annotations" : "Show Annotations",
                            systemImage: viewModel.showAnnotations ? "pencil.tip.crop.circle.fill" : "pencil.tip.crop.circle"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                
                // Next chapter
                if let next = viewModel.nextChapter {
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

*/

//
//  ChapterView.swift
//  WrittenWord
//
//  Updated with bottom sheet interlinear panel
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

    // Force recreation counter for settings changes
    @State private var textViewRecreationID = UUID()
    
    let onChapterChange: (Chapter) -> Void
    
    init(chapter: Chapter, onChapterChange: @escaping (Chapter) -> Void) {
        self.chapter = chapter
        self.onChapterChange = onChapterChange
    }
    
    var body: some View {
        Group {
            if let vm = viewModel {
                chapterContentView(vm)
            } else {
                ProgressView()
            }
        }
        .task(id: chapter.id) {
            if viewModel == nil || viewModel?.chapter.id != chapter.id {
                debugLog("lifecycle", "🔄 ChapterView: Creating/updating viewModel for chapter \(chapter.number)")
                viewModel = ChapterViewModel(chapter: chapter, modelContext: modelContext)
                await viewModel?.loadChapterNote()
            }
        }
        .onChange(of: lineSpacing) { _, newValue in
            debugLog("settings", "📏 ChapterView: Line spacing changed to \(newValue), recreating text view")
            textViewRecreationID = UUID()
        }
        .onChange(of: fontSize) { _, newValue in
            debugLog("settings", "🔤 ChapterView: Font size changed to \(newValue), recreating text view")
            textViewRecreationID = UUID()
        }
        .onChange(of: fontFamily) { _, newValue in
            debugLog("settings", "🖋️ ChapterView: Font family changed to \(newValue.rawValue), recreating text view")
            textViewRecreationID = UUID()
        }
        .onChange(of: colorTheme) { _, newValue in
            debugLog("settings", "🎨 ChapterView: Color theme changed to \(newValue.rawValue), recreating text view")
            textViewRecreationID = UUID()
        }
    }
    
    @ViewBuilder
    private func chapterContentView(_ vm: ChapterViewModel) -> some View {
        @Bindable var viewModel = vm
        
        ZStack {
            colorTheme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                if viewModel.showAnnotations {
                    AnnotationToolbar(
                        selectedTool: $viewModel.selectedTool,
                        selectedColor: $viewModel.selectedColor,
                        penWidth: $viewModel.penWidth,
                        showingColorPicker: $viewModel.showingColorPicker
                    )
                    Divider()
                }
                
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
                
                chapterContent(vm)
            }
            
            // Bottom sheet for interlinear lookup
            if viewModel.showInterlinearLookup, let word = viewModel.selectedWord {
                VStack {
                    Spacer()
                    
                    InterlinearBottomSheet(
                        word: word,
                        onDismiss: {
                            viewModel.showInterlinearLookup = false
                            viewModel.selectedWord = nil
                        }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.showInterlinearLookup)
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
            ScrollViewReader { proxy in
                ScrollView {
                    let _ = debugLog("rendering", "🔧 Building text view with settings: fontSize=\(fontSize), lineSpacing=\(lineSpacing), font=\(fontFamily.rawValue), theme=\(colorTheme.rawValue)")
                    
                    WordSelectableChapterTextView(
                        verses: vm.filteredVerses,
                        highlights: vm.filteredVerses.flatMap { verse in
                            vm.highlightsForVerse(verse.id)
                        },
                        fontSize: fontSize,
                        fontFamily: fontFamily,
                        lineSpacing: lineSpacing,
                        colorTheme: colorTheme,
                        onTextSelected: { verse, range, text in
                            vm.selectTextForHighlight(verse: verse, range: range, text: text)
                        }
                    )
                    .id(textViewRecreationID)
                    .padding(.vertical)
                    
                    if let nextChapter = vm.nextChapter, vm.searchText.isEmpty {
                        Button {
                            onChapterChange(nextChapter)
                        } label: {
                            HStack {
                                Text("Continue to \(nextChapter.book?.name ?? "") \(nextChapter.number)")
                                    .font(.headline)
                                Image(systemName: "arrow.right.circle.fill")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                    }
                }
                .allowsHitTesting(vm.selectedTool == .none)
            }
            
            if vm.showAnnotations {
                GeometryReader { geometry in
                    FullPageAnnotationCanvas(
                        note: vm.chapterNote,
                        selectedTool: vm.convertToDrawingTool(),
                        selectedColor: vm.selectedColor,
                        penWidth: vm.penWidth,
                        canvasView: vm.bindingForCanvasView()
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent(_ viewModel: ChapterViewModel) -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                withAnimation {
                    viewModel.toggleAnnotations()
                }
            } label: {
                Image(systemName: viewModel.showAnnotations ? "pencil.tip.crop.circle.fill" : "pencil.tip.crop.circle")
                    .foregroundColor(viewModel.showAnnotations ? .blue : .primary)
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 8) {
                if let previous = viewModel.previousChapter {
                    Button {
                        onChapterChange(previous)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
                
                Menu {
                    Button {
                        viewModel.selectedVerse = nil
                        viewModel.showingDrawing = true
                    } label: {
                        Label("Full Page Note", systemImage: "note.text.badge.plus")
                    }
                    
                    Button(action: viewModel.bookmarkChapter) {
                        Label("Bookmark Chapter", systemImage: "bookmark.fill")
                    }
                    
                    Divider()
                    
                    Button {
                        withAnimation {
                            viewModel.toggleAnnotations()
                        }
                    } label: {
                        Label(
                            viewModel.showAnnotations ? "Hide Annotations" : "Show Annotations",
                            systemImage: viewModel.showAnnotations ? "pencil.tip.crop.circle.fill" : "pencil.tip.crop.circle"
                        )
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                
                if let next = viewModel.nextChapter {
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
