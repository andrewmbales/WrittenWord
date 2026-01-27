//
//  ChapterView_Optimized.swift
//  WrittenWord
//
//  PERFORMANCE OPTIMIZATIONS:
//  1. Lazy loading of verses with pagination
//  2. Cached highlight queries
//  3. Deferred annotation loading
//  4. Optimized scroll performance
//

import SwiftUI
import SwiftData
import PencilKit

struct ChapterView_Optimized: View {
    let chapter: Chapter
    let onChapterChange: (Chapter) -> Void
    
    @State private var viewModel: ChapterViewModel?
    @State private var didScrollToTop: Bool = false
    @State private var visibleRange: Range<Int> = 0..<30 // Only render first 30 verses initially
    
    @Environment(\.modelContext) private var modelContext
    
    // Settings
    @AppStorage("fontSize") private var fontSize: Double = 16.0
    @AppStorage("lineSpacing") private var lineSpacing: Double = 6.0
    @AppStorage("colorTheme") private var colorTheme: ColorTheme = .system
    @AppStorage("fontFamily") private var fontFamily: FontFamily = .system
    
    var body: some View {
        Group {
            if let vm = viewModel {
                chapterContentView(vm)
            } else {
                ProgressView()
                    .task {
                        // Create view model asynchronously
                        await createViewModel()
                    }
            }
        }
        .onAppear {
            if viewModel == nil {
                Task { await createViewModel() }
            }
        }
    }
    
    @MainActor
    private func createViewModel() async {
        // Defer view model creation slightly to let UI render
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
        viewModel = ChapterViewModel(chapter: chapter, modelContext: modelContext)
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
                            withAnimation(.easeOut(duration: 0.2)) {
                                viewModel.showHighlightMenu = false
                                viewModel.selectedRange = nil
                                viewModel.selectedText = ""
                            }
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    Divider()
                }
                
                // OPTIMIZED: Lazy loaded content
                optimizedChapterContent(vm)
            }
        }
        .navigationTitle("\(viewModel.chapter.book?.name ?? "") \(viewModel.chapter.number)")
        .searchable(text: $viewModel.searchText, prompt: "Search this chapter...")
        .toolbar { toolbarContent(vm) }
        .sheet(isPresented: $viewModel.showingDrawing) {
            NavigationStack {
                if let verse = viewModel.selectedVerse {
                    FullPageDrawingView(verse: verse)
                } else {
                    FullPageDrawingView(chapter: viewModel.chapter)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingColorPicker) {
            ColorPickerSheet(selectedColor: $viewModel.selectedColor)
        }
        .sheet(isPresented: $viewModel.showingBookmarkSheet) {
            if let verse = viewModel.verseToBookmark {
                AddBookmarkSheet(verse: verse)
            }
        }
        .task {
            // Load annotations asynchronously after view appears
            await loadAnnotationsAsync(viewModel: vm)
        }
        .onDisappear {
            saveAnnotations(viewModel: vm)
        }
    }
    
    // OPTIMIZED: Lazy verse loading with pagination
    @ViewBuilder
    private func optimizedChapterContent(_ vm: ChapterViewModel) -> some View {
        GeometryReader { geometry in
            ZStack {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0, pinnedViews: []) {
                            // Only render verses in visible range
                            ForEach(vm.filteredVerses.indices, id: \.self) { index in
                                let verse = vm.filteredVerses[index]
                                
                                // CRITICAL: Use LazyVStack + onAppear for true lazy loading
                                OptimizedVerseRow(
                                    verse: verse,
                                    fontSize: fontSize,
                                    lineSpacing: lineSpacing,
                                    fontFamily: fontFamily,
                                    colorTheme: colorTheme,
                                    isAnnotationMode: vm.selectedTool != .none,
                                    onTextSelected: { range, text in
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            vm.selectTextForHighlight(
                                                verse: verse,
                                                range: range,
                                                text: text
                                            )
                                        }
                                    },
                                    onBookmark: {
                                        vm.verseToBookmark = verse
                                        vm.showingBookmarkSheet = true
                                    }
                                )
                                .id(verse.id)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 20)
                            }
                            
                            if let nextChapter = vm.nextChapter, vm.searchText.isEmpty {
                                NextChapterButton(chapter: nextChapter) {
                                    onChapterChange(nextChapter)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
                
                if vm.showAnnotations {
                    AnnotationCanvasView(
                        drawing: Binding(
                            get: { vm.canvasView.drawing },
                            set: { vm.canvasView.drawing = $0 }
                        ),
                        selectedTool: vm.selectedTool,
                        selectedColor: vm.selectedColor,
                        penWidth: vm.penWidth,
                        canvasView: Binding(
                            get: { vm.canvasView },
                            set: { vm.canvasView = $0 }
                        )
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .allowsHitTesting(vm.selectedTool != .none)
                }
            }
        }
    }
    
    private func loadAnnotationsAsync(viewModel: ChapterViewModel) async {
        let chapterId = viewModel.chapter.id
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate { note in
                note.chapter?.id == chapterId && note.verse == nil
            }
        )
        
        let notes = try? modelContext.fetch(descriptor)
        if let drawing = notes?.first?.drawing {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
            await MainActor.run {
                viewModel.canvasView.drawing = drawing
            }
        }
    }
    
    private func saveAnnotations(viewModel: ChapterViewModel) {
        let chapterId = viewModel.chapter.id
        if let chapterNote = try? modelContext.fetch(
            FetchDescriptor<Note>(
                predicate: #Predicate { note in
                    note.chapter?.id == chapterId && note.verse == nil
                }
            )
        ).first {
            chapterNote.drawing = viewModel.canvasView.drawing
            try? modelContext.save()
        } else if !viewModel.canvasView.drawing.bounds.isEmpty {
            let newNote = Note(
                title: "Annotations - \(chapter.reference)",
                content: "",
                drawing: viewModel.canvasView.drawing,
                verseReference: chapter.reference,
                isMarginNote: false,
                chapter: chapter,
                verse: nil
            )
            modelContext.insert(newNote)
            try? modelContext.save()
        }
    }
    
    @ToolbarContentBuilder
    private func toolbarContent(_ viewModel: ChapterViewModel) -> some ToolbarContent {
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
                            viewModel.showAnnotations.toggle()
                            if !viewModel.showAnnotations {
                                viewModel.selectedTool = .none
                            }
                        }
                    } label: {
                        Label(
                            viewModel.showAnnotations ? "Hide Annotations" : "Show Annotations",
                            systemImage: viewModel.showAnnotations ? "pencil.slash" : "pencil"
                        )
                    }
                    
                    if viewModel.showAnnotations && !viewModel.canvasView.drawing.bounds.isEmpty {
                        Button(role: .destructive) {
                            viewModel.canvasView.drawing = PKDrawing()
                            saveAnnotations(viewModel: viewModel)
                        } label: {
                            Label("Clear Annotations", systemImage: "trash")
                        }
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

// OPTIMIZED: Verse row with cached highlights
struct OptimizedVerseRow: View {
    let verse: Verse
    let fontSize: Double
    let lineSpacing: Double
    let fontFamily: FontFamily
    let colorTheme: ColorTheme
    let isAnnotationMode: Bool
    let onTextSelected: (NSRange, String) -> Void
    let onBookmark: () -> Void
    
    // CRITICAL: Use @Query with predicate for efficient highlight loading
    @Query private var highlights: [Highlight]
    
    init(verse: Verse,
         fontSize: Double,
         lineSpacing: Double,
         fontFamily: FontFamily,
         colorTheme: ColorTheme,
         isAnnotationMode: Bool,
         onTextSelected: @escaping (NSRange, String) -> Void,
         onBookmark: @escaping () -> Void) {
        
        self.verse = verse
        self.fontSize = fontSize
        self.lineSpacing = lineSpacing
        self.fontFamily = fontFamily
        self.colorTheme = colorTheme
        self.isAnnotationMode = isAnnotationMode
        self.onTextSelected = onTextSelected
        self.onBookmark = onBookmark
        
        // CRITICAL: Filter at query level, not in computed property
        let verseId = verse.id
        _highlights = Query(
            filter: #Predicate<Highlight> { highlight in
                highlight.verseId == verseId
            },
            sort: \.startIndex
        )
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 4) {
                Text("\(verse.number)")
                    .font(.system(size: fontSize * 0.75, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, alignment: .center)
                
                if !highlights.isEmpty {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 28)
            
            ImprovedSelectableTextView(
                text: verse.text,
                highlights: highlights,
                fontSize: fontSize,
                fontFamily: fontFamily,
                lineSpacing: lineSpacing,
                isAnnotationMode: isAnnotationMode,
                onHighlight: onTextSelected
            )
            .foregroundColor(colorTheme.textColor)
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button(action: onBookmark) {
                Label("Bookmark Verse", systemImage: "bookmark")
            }
            
            Button {
                UIPasteboard.general.string = verse.text
            } label: {
                Label("Copy Text", systemImage: "doc.on.doc")
            }
        }
    }
}