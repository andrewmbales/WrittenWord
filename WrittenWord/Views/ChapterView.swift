//
//  ChapterView.swift - SIMPLE APPROACH
//  WrittenWord
//
//  Let parent (MainView) handle positioning, ChapterView just fills space
//
import SwiftUI
import SwiftData
import PencilKit

struct ChapterView: View {
    let chapter: Chapter
    @Environment(\.modelContext) private var modelContext
    @Query private var allNotes: [Note]
    @Query private var allHighlights: [Highlight]
    
    @State private var showingDrawing = false
    @State private var selectedVerse: Verse?
    @State private var showAnnotations = true
    @State private var selectedTool: AnnotationTool = .none
    @State private var selectedColor: Color = .black
    @State private var penWidth: CGFloat = 1.0
    @State private var canvasView = PKCanvasView()
    @State private var showingColorPicker = false
    @State private var pendingSave = false
    
    // Phase 1: Highlighting features
    @State private var showHighlightMenu = false
    @State private var selectedText = ""
    @State private var selectedRange: NSRange?
    @State private var selectedHighlightColor: HighlightColor = .yellow
    @State private var searchText = ""
    
    // Phase 2: Bookmarks
    @State private var showingBookmarkSheet = false
    @State private var verseToBookmark: Verse?
    
    // Settings
    @AppStorage("fontSize") private var fontSize: Double = 16.0
    @AppStorage("lineSpacing") private var lineSpacing: Double = 6.0
    @AppStorage("colorTheme") private var colorTheme: ColorTheme = .system
    @AppStorage("fontFamily") private var fontFamily: FontFamily = .system
    
    let onChapterChange: (Chapter) -> Void
    
    enum AnnotationTool: String, CaseIterable {
        case none = "none"
        case pen = "pencil"
        case highlighter = "highlighter"
        case eraser = "eraser.fill"
        case lasso = "lasso"
        
        var icon: String { 
            switch self {
            case .none: return "none"
            default: return rawValue
            }
        }
    }
    
    var sortedVerses: [Verse] {
        chapter.verses.sorted { $0.number < $1.number }
    }
    
    var filteredVerses: [Verse] {
        if searchText.isEmpty {
            return sortedVerses
        }
        return sortedVerses.filter { verse in
            verse.text.localizedCaseInsensitiveContains(searchText) ||
            "\(verse.number)".contains(searchText)
        }
    }
    
    var chapterNotes: [Note] {
        allNotes.filter { note in
            if let noteChapter = note.chapter {
                return noteChapter.id == chapter.id
            }
            if let noteVerse = note.verse, let verseChapter = noteVerse.chapter {
                return verseChapter.id == chapter.id
            }
            return false
        }
    }
    
    func getChapterDrawing() -> Note? {
        chapterNotes.first { $0.chapter?.id == chapter.id && $0.verse == nil }
    }
    
    func getOrCreateChapterDrawing() -> Note {
        if let existing = getChapterDrawing() {
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
        pendingSave = true
        return newNote
    }
    
    private func performBackgroundSave() {
        if pendingSave {
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                try? modelContext.save()
                pendingSave = false
            }
        }
    }
    
    private var previousChapter: Chapter? {
        guard let book = chapter.book else { return nil }
        let chapters = book.chapters.sorted { $0.number < $1.number }
        let currentIndex = chapters.firstIndex(of: chapter) ?? 0
        if currentIndex > 0 {
            return chapters[currentIndex - 1]
        }
        return nil
    }
    
    private var nextChapter: Chapter? {
        guard let book = chapter.book else { return nil }
        let chapters = book.chapters.sorted { $0.number < $1.number }
        let currentIndex = chapters.firstIndex(of: chapter) ?? 0
        if currentIndex < chapters.count - 1 {
            return chapters[currentIndex + 1]
        }
        return nil
    }
    
    var body: some View {
        ZStack {
            // Background
            colorTheme.backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Annotation toolbar
                if showAnnotations {
                    AnnotationToolbar(
                        selectedTool: $selectedTool,
                        selectedColor: $selectedColor,
                        penWidth: $penWidth,
                        showingColorPicker: $showingColorPicker
                    )
                    Divider()
                }
                
                // Highlight palette (when text is selected)
                if showHighlightMenu {
                    HighlightPalette(
                        selectedColor: $selectedHighlightColor,
                        onHighlight: { color in
                            createHighlight(color: color)
                        },
                        onDismiss: {
                            showHighlightMenu = false
                            selectedRange = nil
                            selectedText = ""
                        }
                    )
                    .transition(.move(edge: .top).combined(with: .opacity))
                    Divider()
                }
                
                // Main content area with annotation layer
                ZStack {
                    // Scrollable verse content
                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(filteredVerses) { verse in
                                    EnhancedVerseRow(
                                        verse: verse,
                                        fontSize: fontSize,
                                        lineSpacing: lineSpacing,
                                        fontFamily: fontFamily,
                                        onTextSelected: { range, text in
                                            selectedVerse = verse
                                            selectedRange = range
                                            selectedText = text
                                            withAnimation(.spring(response: 0.3)) {
                                                showHighlightMenu = true
                                            }
                                        },
                                        onBookmark: {
                                            verseToBookmark = verse
                                            showingBookmarkSheet = true
                                        }
                                    )
                                    .id(verse.id)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 20)
                                }
                                
                                // Next chapter button
                                if let nextChapter = nextChapter, searchText.isEmpty {
                                    NextChapterButton(chapter: nextChapter, onTap: {
                                        onChapterChange(nextChapter)
                                    })
                                }
                            }
                            .padding(.vertical)
                            .onAppear {
                                if let firstVerse = filteredVerses.first {
                                    proxy.scrollTo(firstVerse.id, anchor: .top)
                                }
                            }
                        }
                    }
                    
                    // Full-page annotation canvas overlay
                    if showAnnotations {
                        FullPageAnnotationCanvas(
                            note: getOrCreateChapterDrawing(),
                            selectedTool: selectedTool,
                            selectedColor: selectedColor,
                            penWidth: penWidth,
                            canvasView: $canvasView
                        )
                        .allowsHitTesting(selectedTool != .none)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)  // Fill all available space
        .navigationTitle("\(chapter.book?.name ?? "") \(chapter.number)")
        .searchable(text: $searchText, prompt: "Search this chapter...")
        .toolbar {
            toolbarContent
        }
        .sheet(isPresented: $showingDrawing) {
            NavigationStack {
                if let verse = selectedVerse {
                    FullPageDrawingView(verse: verse)
                } else {
                    FullPageDrawingView(chapter: chapter)
                }
            }
        }
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerSheet(selectedColor: $selectedColor)
        }
        .sheet(item: $verseToBookmark) { verse in
            AddBookmarkSheet(verse: verse)
        }
        .onAppear {
            performBackgroundSave()
            // Load existing drawing
            if let chapterNote = getChapterDrawing() {
                canvasView.drawing = chapterNote.drawing
            }
        }
        .onDisappear {
            // Save canvas drawing
            if let chapterNote = getChapterDrawing() {
                chapterNote.drawing = canvasView.drawing
            }
            if pendingSave {
                try? modelContext.save()
                pendingSave = false
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            HStack(spacing: 8) {
                if let previous = previousChapter {
                    Button {
                        onChapterChange(previous)
                    } label: {
                        Image(systemName: "chevron.left")
                    }
                }
                
                Menu {
                    Button {
                        selectedVerse = nil
                        showingDrawing = true
                    } label: {
                        Label("Full Page Note", systemImage: "note.text.badge.plus")
                    }
                    
                    Button {
                        // Bookmark entire chapter
                        let bookmark = Bookmark(
                            title: "",
                            chapter: chapter,
                            category: BookmarkCategory.general.rawValue,
                            color: BookmarkCategory.general.color
                        )
                        modelContext.insert(bookmark)
                        try? modelContext.save()
                    } label: {
                        Label("Bookmark Chapter", systemImage: "bookmark.fill")
                    }
                    
                    Divider()
                    
                    Button {
                        withAnimation {
                            showAnnotations.toggle()
                        }
                    } label: {
                        Label(
                            showAnnotations ? "Hide Annotations" : "Show Annotations",
                            systemImage: showAnnotations ? "pencil.slash" : "pencil"
                        )
                    }
                    
                    if showAnnotations {
                        Button(role: .destructive) {
                            // Clear all annotations
                            canvasView.drawing = PKDrawing()
                            if let chapterNote = getChapterDrawing() {
                                chapterNote.drawing = PKDrawing()
                                try? modelContext.save()
                            }
                        } label: {
                            Label("Clear Annotations", systemImage: "trash")
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                
                if let next = nextChapter {
                    Button {
                        onChapterChange(next)
                    } label: {
                        Image(systemName: "chevron.right")
                    }
                }
            }
        }
        
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                NotificationCenter.default.post(name: .showNotesColumn, object: nil)
            } label: {
                Image(systemName: "sidebar.right")
            }
        }
    }
    
    private func createHighlight(color: HighlightColor) {
        guard let selectedVerse = selectedVerse,
              let range = selectedRange else {
            return
        }
        
        let highlight = Highlight(
            verseId: selectedVerse.id,
            startIndex: range.location,
            endIndex: range.location + range.length,
            color: color.color,
            text: selectedText,
            verse: selectedVerse
        )
        
        modelContext.insert(highlight)
        try? modelContext.save()
        
        // Reset selection
        showHighlightMenu = false
        selectedRange = nil
        selectedText = ""
    }
}

// MARK: - Enhanced Verse Row
struct EnhancedVerseRow: View {
    let verse: Verse
    let fontSize: Double
    let lineSpacing: Double
    let fontFamily: FontFamily
    let onTextSelected: (NSRange, String) -> Void
    let onBookmark: () -> Void
    
    @Environment(\.modelContext) private var modelContext
    @Query private var allHighlights: [Highlight]
    @AppStorage("colorTheme") private var colorTheme: ColorTheme = .system
    
    var verseHighlights: [Highlight] {
        allHighlights.filter { $0.verseId == verse.id }
    }
    
    var hasHighlights: Bool {
        !verseHighlights.isEmpty
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Verse number with indicator
            VStack(spacing: 4) {
                Text("\(verse.number)")
                    .font(.system(size: fontSize * 0.75, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(Color.accentColor.opacity(0.1))
                    .clipShape(Circle())
                
                if hasHighlights {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 6, height: 6)
                }
            }
            .frame(width: 40)
            
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(colorTheme.textColor)
            .fixedSize(horizontal: false, vertical: true)
        }
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onBookmark()
            } label: {
                Label("Bookmark", systemImage: "bookmark")
            }
            
            Button {
                UIPasteboard.general.string = verse.text
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            
            Button {
                // Share verse
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
    }
}

// MARK: - Full Page Annotation Canvas
struct FullPageAnnotationCanvas: View {
    @Bindable var note: Note
    let selectedTool: ChapterView.AnnotationTool
    let selectedColor: Color
    let penWidth: CGFloat
    @Binding var canvasView: PKCanvasView
    
    var body: some View {
        AnnotationCanvasView(
            drawing: Binding(
                get: { note.drawing },
                set: { newDrawing in
                    note.drawing = newDrawing
                }
            ),
            selectedTool: selectedTool,
            selectedColor: selectedColor,
            penWidth: penWidth,
            canvasView: $canvasView
        )
        .background(Color.clear)
        .allowsHitTesting(selectedTool != .none)
    }
}

struct AnnotationCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let selectedTool: ChapterView.AnnotationTool
    let selectedColor: Color
    let penWidth: CGFloat
    @Binding var canvasView: PKCanvasView
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.backgroundColor = .clear
        canvasView.isOpaque = false
        canvasView.drawing = drawing
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = context.coordinator
        canvasView.alwaysBounceVertical = true
        canvasView.alwaysBounceHorizontal = false
        updateTool()
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
        updateTool()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func updateTool() {
        let uiColor = UIColor(selectedColor)
        
        switch selectedTool {
        case .none:
            break
        case .pen:
            canvasView.tool = PKInkingTool(.pen, color: uiColor, width: penWidth)
        case .highlighter:
            canvasView.tool = PKInkingTool(.marker, color: uiColor.withAlphaComponent(0.3), width: penWidth * 3)
        case .eraser:
            canvasView.tool = PKEraserTool(.vector)
        case .lasso:
            canvasView.tool = PKLassoTool()
        }
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: AnnotationCanvasView
        
        init(_ parent: AnnotationCanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
}

// MARK: - Annotation Toolbar
struct AnnotationToolbar: View {
    @Binding var selectedTool: ChapterView.AnnotationTool
    @Binding var selectedColor: Color
    @Binding var penWidth: CGFloat
    @Binding var showingColorPicker: Bool
    
    let predefinedColors: [Color] = [
        .black, .gray, .red, .orange, .yellow,
        .green, .blue, .purple, .brown, .pink
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(ChapterView.AnnotationTool.allCases, id: \.self) { tool in
                    Button(action: { selectedTool = tool }) {
                        Image(systemName: tool.icon)
                            .font(.title3)
                            .frame(width: 44, height: 44)
                            .background(selectedTool == tool ? Color.blue.opacity(0.2) : Color.clear)
                            .cornerRadius(8)
                    }
                    .foregroundColor(selectedTool == tool ? .blue : .primary)
                }
                
                Divider().frame(height: 40)
                
                ForEach(predefinedColors, id: \.self) { color in
                    Button(action: { selectedColor = color }) {
                        Circle()
                            .fill(color)
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .stroke(selectedColor == color ? Color.blue : Color.gray.opacity(0.3), lineWidth: 2)
                            )
                    }
                }
                
                Button(action: { showingColorPicker = true }) {
                    ZStack {
                        Circle()
                            .fill(
                                AngularGradient(
                                    gradient: Gradient(colors: [.red, .yellow, .green, .blue, .purple, .red]),
                                    center: .center
                                )
                            )
                            .frame(width: 28, height: 28)
                        Image(systemName: "plus")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                }
                
                Divider().frame(height: 40)
                
                if selectedTool != .eraser && selectedTool != .lasso && selectedTool != .none {
                    HStack(spacing: 8) {
                        Image(systemName: "line.diagonal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Slider(value: $penWidth, in: 1...12)
                            .frame(width: 100)
                            .tint(.blue)
                        
                        Text("\(Int(penWidth))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 25)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }
}

// MARK: - Supporting Components
struct HighlightPalette: View {
    @Binding var selectedColor: HighlightColor
    let onHighlight: (HighlightColor) -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Text("Highlight:")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            ForEach(HighlightColor.allCases, id: \.self) { color in
                Button {
                    selectedColor = color
                    onHighlight(color)
                } label: {
                    Circle()
                        .fill(color.color)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.primary.opacity(0.2), lineWidth: 1)
                        )
                        .overlay(
                            selectedColor == color ?
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            : nil
                        )
                }
            }
            
            Spacer()
            
            Button("Cancel") {
                onDismiss()
            }
            .font(.subheadline)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
}

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
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}