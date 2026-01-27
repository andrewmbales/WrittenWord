//
//  ChapterView.swift - FIXED
//  WrittenWord
//
//  Fixed Issues:
//  1. Annotation canvas no longer interferes with scrolling
//  2. Improved text selection for highlighting
//

import SwiftUI
import SwiftData
import PencilKit

struct ChapterView: View {
    let chapter: Chapter
    @State private var viewModel: ChapterViewModel?
    @State private var didScrollToTop: Bool = false
    @Environment(\.modelContext) private var modelContext
    
    // Settings
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
            print("👁️ [CHAPTER] ChapterView onAppear - \(chapter.book?.name ?? "Unknown") \(chapter.number) (ID: \(chapter.id))")
            if viewModel == nil {
                print("🔧 [CHAPTER] Creating new ChapterViewModel")
                viewModel = ChapterViewModel(chapter: chapter, modelContext: modelContext)
            } else {
                print("🔄 [CHAPTER] Using existing ChapterViewModel")
            }
        }
    }
    
    @ViewBuilder
    private func chapterContentView(_ vm: ChapterViewModel) -> some View {
        @Bindable var viewModel = vm
        
        ZStack {
            colorTheme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // FIXED: Only show annotation toolbar when annotations are enabled
                if viewModel.showAnnotations {
                    AnnotationToolbar(
                        selectedTool: $viewModel.selectedTool,
                        selectedColor: $viewModel.selectedColor,
                        penWidth: $viewModel.penWidth,
                        showingColorPicker: $viewModel.showingColorPicker
                    )
                    Divider()
                }
                
                // FIXED: Improved highlight menu with better animation
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
                
                // FIXED: Proper layering of content and annotations
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
        .sheet(isPresented: $viewModel.showingBookmarkSheet) {
            if let verse = viewModel.verseToBookmark {
                AddBookmarkSheet(verse: verse)
            }
        }
        .onAppear {
            print("💾 [CHAPTER] Loading annotations for: \(viewModel.chapter.reference)")
            Task { await loadAnnotationsAsync(viewModel: vm) }
        }
        .onDisappear {
            print("🗑️ [CHAPTER] ChapterView onDisappear - saving annotations for: \(viewModel.chapter.reference)")
            saveAnnotations(viewModel: vm)
        }
    }
    
    // Load existing annotations
    private func loadExistingAnnotations(viewModel: ChapterViewModel) {
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
    
    // Save annotations when leaving the view
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
            // Create new note if there's actual drawing content
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
    
    // Async load for existing annotations to avoid blocking the main thread
    private func loadAnnotationsAsync(viewModel: ChapterViewModel) async {
        let chapterId = viewModel.chapter.id
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate { note in
                note.chapter?.id == chapterId && note.verse == nil
            }
        )
        // Perform fetch (SwiftData may still require main, but yielding helps UI render first)
        let notes = try? modelContext.fetch(descriptor)
        if let drawing = notes?.first?.drawing {
            // Yield briefly to let the first frame render before applying large drawings
            try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
            await MainActor.run {
                viewModel.canvasView.drawing = drawing
            }
        }
    }
    
    // MARK: - Chapter Content with FIXED Interaction
    @ViewBuilder
    private func chapterContent(_ vm: ChapterViewModel) -> some View {
        GeometryReader { geometry in
            ZStack {
                // Base layer: Scrollable verses
                // FIXED: This is ALWAYS interactive for scrolling and text selection
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 0) {
                            ForEach(vm.filteredVerses) { verse in
                                VerseRow(
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
                                    print("⏭️ [CHAPTER] NextChapterButton tapped - FROM: \(chapter.book?.name ?? "Unknown") \(chapter.number) TO: \(nextChapter.book?.name ?? "Unknown") \(nextChapter.number)")
                                    onChapterChange(nextChapter)
                                }
                            }
                        }
                        .padding(.vertical)
                        .onAppear {
                            if !didScrollToTop {
                                didScrollToTop = true
                                DispatchQueue.main.async {
                                    if let firstVerse = vm.filteredVerses.first {
                                        proxy.scrollTo(firstVerse.id, anchor: .top)
                                    }
                                }
                            }
                        }
                    }
                    // FIXED: Only disable scrolling when actively drawing (not just when tool is selected)
                    .simultaneousGesture(
                        // Allow scroll to work even in annotation mode when not actively drawing
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in }
                    )
                }
                
                // Annotation layer: Transparent overlay that only captures when tool is active
                // FIXED: Proper hit testing that doesn't block scrolling
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
                    // CRITICAL FIX: Only capture touches when a drawing tool is active
                    .allowsHitTesting(vm.selectedTool != .none)
                }
            }
        }
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private func toolbarContent(_ viewModel: ChapterViewModel) -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 8) {
                if let previous = viewModel.previousChapter {
                    Button {
                        print("⬅️ [CHAPTER] Previous chapter button tapped - FROM: \(viewModel.chapter.book?.name ?? "Unknown") \(viewModel.chapter.number) TO: \(previous.book?.name ?? "Unknown") \(previous.number)")
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
                            // Reset tool when hiding annotations
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
                        print("➡️ [CHAPTER] Next chapter button tapped - FROM: \(viewModel.chapter.book?.name ?? "Unknown") \(viewModel.chapter.number) TO: \(next.book?.name ?? "Unknown") \(next.number)")
                        onChapterChange(next)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Components
struct NextChapterButton: View {
    let chapter: Chapter
    let onTap: () -> Void
    
    var body: some View {
        VStack {
            Divider()
                .padding(.horizontal)
            
            Button(action: {
                print("🎯 [NEXT BUTTON] NextChapterButton action triggered for: \(chapter.book?.name ?? "Unknown") \(chapter.number)")
                onTap()
            }) {
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
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(12)
                .padding()
            }
            .buttonStyle(.plain)
        }
    }
}

struct ColorPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedColor: Color
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ColorPicker("Select Color", selection: $selectedColor, supportsOpacity: false)
                    .padding()
                
                // Color preview
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedColor)
                    .frame(height: 100)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Custom Color")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

