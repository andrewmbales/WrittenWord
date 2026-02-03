//
//  ChapterView.swift
//  WrittenWord
//
//  Optimized chapter view with MVVM pattern, line spacing support, and easy annotation access
//

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
        .onAppear {
            if viewModel == nil {
                viewModel = ChapterViewModel(chapter: chapter, modelContext: modelContext)
            }
        }
    }
    
    @ViewBuilder
    private func chapterContentView(_ vm: ChapterViewModel) -> some View {
        @Bindable var viewModel = vm
        
        ZStack {
            colorTheme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Annotation toolbar (shown when annotations enabled)
                if viewModel.showAnnotations {
                    AnnotationToolbar(
                        selectedTool: $viewModel.selectedTool,
                        selectedColor: $viewModel.selectedColor,
                        penWidth: $viewModel.penWidth,
                        showingColorPicker: $viewModel.showingColorPicker
                    )
                    Divider()
                }
                
                // Highlight palette (shown when text selected)
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
                
                // Main chapter content with annotation overlay
                chapterContent(vm)
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
        .sheet(item: $viewModel.verseToBookmark) { verse in
            AddBookmarkSheet(verse: verse)
        }
        .onAppear {
            // Load existing drawing
            let chapterId = viewModel.chapter.id
            if let chapterNote = try? modelContext.fetch(
                FetchDescriptor<Note>(
                    predicate: #Predicate { note in
                        note.chapter?.id == chapterId && note.verse == nil
                    }
                )
            ).first {
                viewModel.canvasView.drawing = chapterNote.drawing
            }
        }
        .onDisappear {
            // Save canvas drawing
            saveAnnotations(viewModel: vm)
        }
    }
    
    // MARK: - Save Annotations
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
        }
    }
    
    // MARK: - Chapter Content
    @ViewBuilder
    private func chapterContent(_ vm: ChapterViewModel) -> some View {
        ZStack {
            // Base layer: Scrollable verses
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(vm.filteredVerses) { verse in
                            VerseRow(
                                verse: verse,
                                fontSize: fontSize,
                                lineSpacing: lineSpacing,  // ← Passed from @AppStorage
                                fontFamily: fontFamily,
                                colorTheme: colorTheme,
                                onTextSelected: { range, text in
                                    vm.selectTextForHighlight(
                                        verse: verse,
                                        range: range,
                                        text: text
                                    )
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
                            ChapterContinueButton(chapter: nextChapter) {
                                onChapterChange(nextChapter)
                            }
                        }
                    }
                    .padding(.vertical)
                    .onAppear {
                        if let firstVerse = vm.filteredVerses.first {
                            proxy.scrollTo(firstVerse.id, anchor: .top)
                        }
                    }
                }
                // Disable scroll when annotating
                .allowsHitTesting(vm.selectedTool == .none)
            }
            
            // Annotation layer overlay
            if vm.showAnnotations {
                GeometryReader { geometry in
                    FullPageAnnotationCanvas(
                        note: getOrCreateChapterDrawing(),
                        selectedTool: vm.selectedTool,
                        selectedColor: vm.selectedColor,
                        penWidth: vm.penWidth,
                        canvasView: Binding(
                            get: { viewModel?.canvasView ?? PKCanvasView() },
                            set: { viewModel?.canvasView = $0 }
                        )
                    )
                    .frame(width: geometry.size.width, height: geometry.size.height)
                }
            }
        }
    }
    
    // MARK: - Get or Create Chapter Drawing
    private func getOrCreateChapterDrawing() -> Note {
        let chapterId = chapter.id
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate { note in
                note.chapter?.id == chapterId && note.verse == nil
            }
        )
        
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        
        let newNote = Note(
            title: "Annotations - \(chapter.reference)",
            content: "",
            drawing: PKDrawing(),
            verseReference: chapter.reference,
            isMarginNote: false,
            chapter: chapter,
            verse: nil
        )
        modelContext.insert(newNote)
        return newNote
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private func toolbarContent(_ viewModel: ChapterViewModel) -> some ToolbarContent {
        // NEW: Annotation toggle button (prominent placement)
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                withAnimation {
                    viewModel.showAnnotations.toggle()
                    if viewModel.showAnnotations {
                        viewModel.selectedTool = .pen  // Auto-select pen
                    } else {
                        viewModel.selectedTool = .none
                        saveAnnotations(viewModel: viewModel)
                    }
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
                            viewModel.showAnnotations.toggle()
                        }
                    } label: {
                        Label(
                            viewModel.showAnnotations ? "Hide Annotations" : "Show Annotations",
                            systemImage: viewModel.showAnnotations ? "pencil.slash" : "pencil"
                        )
                    }
                    
                    if viewModel.showAnnotations {
                        Button {
                            viewModel.clearAnnotations(
                                canvasView: viewModel.canvasView,
                                chapterNote: try? modelContext.fetch(
                                    FetchDescriptor<Note>(
                                        predicate: #Predicate { note in
                                            note.chapter?.id == viewModel.chapter.id && note.verse == nil
                                        }
                                    )
                                ).first
                            )
                        } label: {
                            Label("Clear Annotations", systemImage: "trash")
                        }
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

// MARK: - Verse Row Component
struct VerseRow: View {
    let verse: Verse
    let fontSize: Double
    let lineSpacing: Double  // ← This gets passed from ChapterView's @AppStorage
    let fontFamily: FontFamily
    let colorTheme: ColorTheme
    let onTextSelected: (NSRange, String) -> Void
    let onBookmark: () -> Void
    
    @Query private var allHighlights: [Highlight]
    @State private var selectedText = ""
    @State private var selectedRange: NSRange?
    @State private var showHighlightMenu = false
    
    var verseHighlights: [Highlight] {
        allHighlights.filter { $0.verseId == verse.id }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Verse number
            VStack(spacing: 4) {
                Text("\(verse.number)")
                    .font(.system(size: fontSize * 0.75, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Circle())
                
                if !verseHighlights.isEmpty {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 40)
            
            // Verse text with proper line spacing
            SelectableTextView(
                text: verse.text,
                highlights: verseHighlights,
                fontSize: fontSize,
                fontFamily: fontFamily,
                lineSpacing: lineSpacing,  // ← Line spacing applied here
                selectedRange: $selectedRange,
                onHighlight: { range, text in
                    onTextSelected(range, text)
                }
            )
            .foregroundColor(colorTheme.textColor)
        }
        .contextMenu {
            Button(action: onBookmark) {
                Label("Bookmark", systemImage: "bookmark")
            }
            
            Button {
                UIPasteboard.general.string = verse.text
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
        }
    }
}

// MARK: - Next Chapter Button
struct ChapterContinueButton: View {
    let chapter: Chapter
    let onTap: () -> Void
    
    var body: some View {
        VStack {
            Divider()
            Button(action: onTap) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Continue Reading")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(chapter.book?.name ?? "") \(chapter.number)")
                            .font(.headline)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Book.self,
        Chapter.self,
        Verse.self,
        configurations: config
    )
    
    let context = container.mainContext
    let book = Book(name: "Genesis", order: 1, testament: "Old")
    let chapter = Chapter(number: 1, book: book)
    let verse = Verse(number: 1, text: "In the beginning God created the heaven and the earth.", chapter: chapter)
    
    context.insert(book)
    context.insert(chapter)
    context.insert(verse)
    
    NavigationStack {
        ChapterView(chapter: chapter) { _ in }
    }
    .modelContainer(container)
}

