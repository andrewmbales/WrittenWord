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

    // ✅ ADD: Force recreation counter
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
                viewModel = ChapterViewModel(chapter: chapter, modelContext: modelContext)
                await viewModel?.loadChapterNote()
            }
        }
        // ✅ ADD: Watch for setting changes and force recreation
        .onChange(of: lineSpacing) { _, _ in
            textViewRecreationID = UUID()
        }
        .onChange(of: fontSize) { _, _ in
            textViewRecreationID = UUID()
        }
        .onChange(of: fontFamily) { _, _ in
            textViewRecreationID = UUID()
        }
        .onChange(of: colorTheme) { _, _ in
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
                
                // Highlight palette (shown when text selected without interlinear data)
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
                
                // Main chapter content with annotation overlay
                chapterContent(vm)
            }
        }
        .navigationTitle("\(vm.chapter.book?.name ?? "") \(vm.chapter.number)")
        .searchable(text: vm.bindingForSearchText(), prompt: "Search this chapter...")
        .toolbar { toolbarContent(vm) }
        .sheet(isPresented: vm.bindingForShowingDrawing()) {
            NavigationStack {
                if let verse = vm.selectedVerse {
                    FullPageDrawingView(verse: verse)
                } else {
                    FullPageDrawingView(chapter: vm.chapter)
                }
            }
        }
        .sheet(isPresented: vm.bindingForShowingColorPicker()) {
            ColorPickerSheet(selectedColor: vm.bindingForSelectedColor())
        }
        .sheet(item: vm.bindingForVerseToBookmark()) { verse in
            AddBookmarkSheet(verse: verse)
        }
        .sheet(isPresented: vm.bindingForShowInterlinearLookup()) {
            if let word = vm.selectedWord {
                InterlinearLookupView(word: word)
            }
        }
        .onChange(of: vm.showAnnotations) { _, newValue in
            if !newValue {
                Task {
                    await vm.saveAnnotations()
                }
            }
        }
        .onChange(of: vm.showInterlinearLookup) { _, newValue in
            // Reset state when interlinear lookup is dismissed
            if !newValue {
                vm.selectedWord = nil
                vm.selectedRange = nil
                vm.selectedText = ""
            }
        }
    }
    
    // MARK: - Chapter Content
    @ViewBuilder
    private func chapterContent(_ vm: ChapterViewModel) -> some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView {
                    // ✅ DEBUG: Print current values
                    let _ = print("🔧 ChapterView Building Text View:")
                    let _ = print("   fontSize: \(fontSize)")
                    let _ = print("   lineSpacing: \(lineSpacing)")
                    let _ = print("   fontFamily: \(fontFamily.rawValue)")
                    let _ = print("   colorTheme: \(colorTheme.rawValue)")
                    let _ = print("   ID: \(fontSize)-\(lineSpacing)-\(fontFamily.rawValue)-\(colorTheme.rawValue)")
                    
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
                    .id(textViewRecreationID)  // ✅ Use UUID that changes on settings change
                    .padding(.vertical)
                    
                    if let nextChapter = vm.nextChapter, vm.searchText.isEmpty {
                        ChapterContinueButton(chapter: nextChapter) {
                            onChapterChange(nextChapter)
                        }
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
                            systemImage: viewModel.showAnnotations ? "pencil.slash" : "pencil"
                        )
                    }
                    
                    if viewModel.showAnnotations {
                        Button(role: .destructive) {
                            Task {
                                await viewModel.clearAnnotations()
                            }
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
    let highlights: [Highlight]  // Now passed from parent instead of querying
    let fontSize: Double
    let lineSpacing: Double
    let fontFamily: FontFamily
    let colorTheme: ColorTheme
    let onTextSelected: (NSRange, String) -> Void
    let onBookmark: () -> Void
    
    @State private var selectedText = ""
    @State private var selectedRange: NSRange?
    @State private var showHighlightMenu = false
    
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
                
                if !highlights.isEmpty {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 40)
            
            // Verse text with proper line spacing
            SelectableTextView(
                text: verse.text,
                highlights: highlights,
                fontSize: fontSize,
                fontFamily: fontFamily,
                lineSpacing: lineSpacing,
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
    
    return NavigationStack {
        ChapterView(chapter: chapter) { _ in }
    }
    .modelContainer(container)
}
