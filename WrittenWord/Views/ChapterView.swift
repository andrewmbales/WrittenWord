//
//  ChapterView.swift - OPTIMIZED
//  WrittenWord
//
//  Refactored to use MVVM pattern with separated concerns
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
                
                // Verse content with annotation overlay (contained within)
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
        }
    }
    
    // MARK: - Chapter Content
    @ViewBuilder
    private func chapterContent(_ vm: ChapterViewModel) -> some View {
        // Overlay annotation canvas ONLY on the scrollable content
        ZStack {
            // Base layer: Scrollable verses
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
                            NextChapterButton(chapter: nextChapter) {
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
                // Disable scroll interaction when annotating
                .allowsHitTesting(vm.selectedTool == .none)
            }
            
            // Annotation layer: ONLY over the verse content
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
    
    // Helper function to get or create chapter drawing
    private func getOrCreateChapterDrawing() -> Note {
        // Check for existing chapter note
        let chapterId = chapter.id
        let descriptor = FetchDescriptor<Note>(
            predicate: #Predicate { note in
                note.chapter?.id == chapterId && note.verse == nil
            }
        )
        
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        
        // Create new chapter note
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
                        }
                    } label: {
                        Label(
                            viewModel.showAnnotations ? "Hide Annotations" : "Show Annotations",
                            systemImage: viewModel.showAnnotations ? "pencil.slash" : "pencil"
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

// MARK: - Verse Row Component
struct VerseRow: View {
    let verse: Verse
    let fontSize: Double
    let lineSpacing: Double
    let fontFamily: FontFamily
    let colorTheme: ColorTheme
    let onTextSelected: (NSRange, String) -> Void
    let onBookmark: () -> Void
    
    @Query private var allHighlights: [Highlight]
    
    var verseHighlights: [Highlight] {
        allHighlights.filter { $0.verseId == verse.id }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Verse number - simplified without circle
            VStack(spacing: 4) {
                Text("\(verse.number)")
                    .font(.system(size: fontSize * 0.75, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(width: 20, alignment: .leading)
                
                if !verseHighlights.isEmpty {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 20)
            
            // Verse text
            SelectableTextView(
                text: verse.text,
                highlights: verseHighlights,
                fontSize: fontSize,
                fontFamily: fontFamily,
                lineSpacing: lineSpacing,
                selectedRange: .constant(nil),
                onHighlight: onTextSelected
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

// MARK: - Supporting Components (kept minimal)
struct NextChapterButton: View {
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
            VStack {
                ColorPicker("Select Color", selection: $selectedColor, supportsOpacity: false)
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