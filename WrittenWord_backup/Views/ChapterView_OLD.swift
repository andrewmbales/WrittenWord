//
//  ChapterView.swift
//  WrittenWord
//
//  Enhanced with Phase 1 improvements
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
    @State private var showMargins = true
    @State private var selectedTool: MarginTool = .pen
    @State private var selectedColor: Color = .black
    @State private var penWidth: CGFloat = 1.0
    @State private var canvasViews: [UUID: PKCanvasView] = [:]
    @State private var showingColorPicker = false
    @State private var pendingSave = false
    
    // Phase 1: New highlighting features
    @State private var showHighlightMenu = false
    @State private var selectedText = ""
    @State private var selectedRange: NSRange?
    @State private var selectedHighlightColor: HighlightColor = .yellow
    @State private var searchText = ""
    @State private var showingHighlightPalette = false

    // Phase 2: Bookmark creation
    @State private var showingBookmarkSheet = false
    @State private var verseToBookmark: Verse?
    
    // Settings
    @AppStorage("fontSize") private var fontSize: Double = 16.0
    @AppStorage("lineSpacing") private var lineSpacing: Double = 6.0
    @AppStorage("colorTheme") private var colorTheme: ColorTheme = .system
    @AppStorage("fontFamily") private var fontFamily: FontFamily = .system
    
    let onChapterChange: (Chapter) -> Void
    
    enum MarginTool: String, CaseIterable {
        case pen = "pencil"
        case highlighter = "highlighter"
        case eraser = "eraser.fill"
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
    
    func getMarginNote(for verse: Verse) -> Note? {
        chapterNotes.first { $0.verse?.id == verse.id && $0.isMarginNote }
    }
    
    func getOrCreateMarginNote(for verse: Verse) -> Note {
        if let existing = getMarginNote(for: verse) {
            return existing
        }
        
        let newNote = Note(
            title: "Margin - \(verse.reference)",
            content: "",
            drawing: PKDrawing(),
            verseReference: verse.reference,
            isMarginNote: true,
            chapter: nil,
            verse: verse
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
        VStack(spacing: 0) {
            // Margin toolbar
            if showMargins {
                MarginToolbar(
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
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(filteredVerses) { verse in
                            VStack(spacing: 0) {
                                HStack(alignment: .top, spacing: 0) {
                                    // Enhanced verse display
                                    EnhancedVerseRow(
                                        verse: verse,
                                        fontSize: fontSize,
                                        lineSpacing: lineSpacing,
                                        fontFamily: fontFamily,
                                        showMargins: showMargins,
                                        onTextSelected: { range, text in
                                            selectedVerse = verse
                                            selectedRange = range
                                            selectedText = text
                                            withAnimation(.spring(response: 0.3)) {
                                                showHighlightMenu = true
                                            }
                                        },
                                        onAddNote: { verse in
                                            selectedVerse = verse
                                            showingDrawing = true
                                        },
                                        onBookmark: { verse in
                                            verseToBookmark = verse
                                            showingBookmarkSheet = true
                                        }
                                    )

                                    
                                    // Margin area
                                    if showMargins {
                                        MarginCanvas(
                                            verse: verse,
                                            note: getOrCreateMarginNote(for: verse),
                                            selectedTool: selectedTool,
                                            selectedColor: selectedColor,
                                            penWidth: penWidth,
                                            canvasViews: $canvasViews
                                        )
                                        .frame(width: 200)
                                        .background(Color(.systemGray6).opacity(0.3))
                                    }
                                }
                                .id(verse.id)
                                
                                Divider()
                            }
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
        }
        .background(colorTheme.backgroundColor)
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
        .sheet(item: $verseToBookmark) { verse in
    AddBookmarkSheet(verse: verse)
}
        .sheet(isPresented: $showingColorPicker) {
            ColorPickerSheet(selectedColor: $selectedColor)
        }
        .sheet(isPresented: $showingBookmarkSheet) {
            if let verse = verseToBookmark {
                AddBookmarkSheet(verse: verse)
            }
        }
        .onAppear {
            performBackgroundSave()
        }
        .onDisappear {
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
                        withAnimation {
                            showingHighlightPalette.toggle()
                        }
                    } label: {
                        Label("Highlight", systemImage: "highlighter")
                    }
                    
                    Divider()
                    Button {
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
                            showMargins.toggle()
                        }
                    } label: {
                        Label(showMargins ? "Hide Margins" : "Show Margins",
                              systemImage: showMargins ? "sidebar.right" : "sidebar.left")
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
    let showMargins: Bool
    let onTextSelected: (NSRange, String) -> Void
    let onAddNote: (Verse) -> Void
    let onBookmark: (Verse) -> Void
    
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
            .frame(maxWidth: showMargins ? .infinity : nil)
            .foregroundColor(colorTheme.textColor)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .contextMenu {
            Button {
                onAddNote(verse)
            } label: {
                Label("Add Note", systemImage: "note.text")
            }
            
            Button {
                onBookmark(verse)
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

// MARK: - Highlight Palette
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

// MARK: - Next Chapter Button
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

// MARK: - Supporting Views (MarginToolbar, MarginCanvas, ColorPickerSheet remain the same)
struct MarginToolbar: View {
    @Binding var selectedTool: ChapterView.MarginTool
    @Binding var selectedColor: Color
    @Binding var penWidth: CGFloat
    @Binding var showingColorPicker: Bool
    
    let predefinedColors: [Color] = [
        .black, .gray, .red, .orange, .yellow,
        .green, .blue, .purple
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(ChapterView.MarginTool.allCases, id: \.self) { tool in
                    Button(action: { selectedTool = tool }) {
                        Image(systemName: tool.rawValue)
                            .font(.title3)
                            .frame(width: 36, height: 36)
                            .background(selectedTool == tool ? Color.blue.opacity(0.2) : Color.clear)
                            .cornerRadius(6)
                    }
                    .foregroundColor(selectedTool == tool ? .blue : .primary)
                }
                
                Divider().frame(height: 30)
                
                ForEach(predefinedColors, id: \.self) { color in
                    Button(action: { selectedColor = color }) {
                        Circle()
                            .fill(color)
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle()
                                    .stroke(selectedColor == color ? Color.blue : Color.clear, lineWidth: 2)
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
                            .frame(width: 24, height: 24)
                        Image(systemName: "plus")
                            .font(.caption2)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                }
                
                Divider().frame(height: 30)
                
                if selectedTool != .eraser {
                    HStack(spacing: 4) {
                        Image(systemName: "line.diagonal")
                            .font(.caption2)
                        Slider(value: $penWidth, in: 1...8)
                            .frame(width: 80)
                        Text("\(Int(penWidth))")
                            .font(.caption2)
                            .frame(width: 20)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .background(Color(.systemGray6))
    }
}

struct MarginCanvas: View {
    let verse: Verse
    @Bindable var note: Note
    let selectedTool: ChapterView.MarginTool
    let selectedColor: Color
    let penWidth: CGFloat
    @Binding var canvasViews: [UUID: PKCanvasView]
    
    var body: some View {
        MarginPencilKitView(
            drawing: Binding(
                get: { note.drawing },
                set: { newDrawing in
                    note.drawing = newDrawing
                }
            ),
            selectedTool: selectedTool,
            selectedColor: selectedColor,
            penWidth: penWidth,
            verseId: verse.id,
            canvasViews: $canvasViews
        )
        .frame(minHeight: 60)
    }
}

struct MarginPencilKitView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let selectedTool: ChapterView.MarginTool
    let selectedColor: Color
    let penWidth: CGFloat
    let verseId: UUID
    @Binding var canvasViews: [UUID: PKCanvasView]
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.drawing = drawing
        canvas.drawingPolicy = .anyInput
        canvas.delegate = context.coordinator
        canvasViews[verseId] = canvas
        updateTool(canvas)
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
        updateTool(uiView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func updateTool(_ canvas: PKCanvasView) {
        let uiColor = UIColor(selectedColor)
        
        switch selectedTool {
        case .pen:
            canvas.tool = PKInkingTool(.pen, color: uiColor, width: penWidth)
        case .highlighter:
            canvas.tool = PKInkingTool(.marker, color: uiColor.withAlphaComponent(0.3), width: penWidth * 2)
        case .eraser:
            canvas.tool = PKEraserTool(.vector)
        }
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: MarginPencilKitView
        
        init(_ parent: MarginPencilKitView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
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