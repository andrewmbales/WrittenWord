//
//  ChapterView.swift
//  WrittenWord
//
//  Created by Andrew Bales on 1/21/26.
//
import SwiftUI
import SwiftData
import PencilKit

struct ChapterView: View {
    let chapter: Chapter
    @Environment(\.modelContext) private var modelContext
    @Query private var allNotes: [Note]
    @State private var showingDrawing = false
    @State private var selectedVerse: Verse?
    @State private var showMargins = true
    @State private var selectedTool: MarginTool = .pen
    @State private var selectedColor: Color = .black
    @State private var penWidth: CGFloat = 1.0
    @State private var canvasViews: [UUID: PKCanvasView] = [:]
    @State private var showingColorPicker = false
    @State private var pendingSave = false
    let onChapterChange: (Chapter) -> Void
    
    enum MarginTool: String, CaseIterable {
        case pen = "pencil"
        case highlighter = "highlighter"
        case eraser = "eraser.fill"
    }
    
    var sortedVerses: [Verse] {
        chapter.verses.sorted { $0.number < $1.number }
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
        
        // Mark for background save to prevent UI freezing
        pendingSave = true
        
        return newNote
    }
    
    private func performBackgroundSave() {
        if pendingSave {
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
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
        guard let book = chapter.book else { 
            print("No book found for chapter")
            return nil 
        }
        let chapters = book.chapters.sorted { $0.number < $1.number }
        let currentIndex = chapters.firstIndex(of: chapter) ?? 0
        print("Current chapter: \(chapter.number), Total chapters: \(chapters.count), Index: \(currentIndex)")
        if currentIndex < chapters.count - 1 {
            let next = chapters[currentIndex + 1]
            print("Next chapter found: \(next.book?.name ?? "") \(next.number)")
            return next
        }
        print("No next chapter available")
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
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(sortedVerses) { verse in
                            HStack(alignment: .top, spacing: 0) {
                                // Verse number and text
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(verse.number)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 30, alignment: .trailing)
                                    
                                    Text(verse.text)
                                        .font(.body)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: showMargins ? .infinity : nil)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                                .contextMenu {
                                    Button {
                                        selectedVerse = verse
                                        showingDrawing = true
                                    } label: {
                                        Label("Full Page Note", systemImage: "note.text")
                                    }
                                }
                                
                                // Margin area for handwriting
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
                        
                        // Add next chapter button at the bottom
                        if let nextChapter = nextChapter {
                            VStack {
                                Divider()
                                Button(action: {
                                    print("Next chapter button tapped: \(nextChapter.book?.name ?? "") \(nextChapter.number)")
                                    onChapterChange(nextChapter)
                                }) {
                                    HStack {
                                        Text("Continue to \(nextChapter.book?.name ?? "") \(nextChapter.number)")
                                            .font(.headline)
                                        Image(systemName: "chevron.right")
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.accentColor.opacity(0.1))
                                    .cornerRadius(10)
                                    .padding()
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .id("nextChapterButton")
                        } else {
                            // Debug: Show when no next chapter is available
                            VStack {
                                Divider()
                                Text("No next chapter available")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding()
                            }
                        }
                    }
                    .padding(.vertical)
                    .onAppear {
                        // Scroll to top when chapter changes
                        if let firstVerse = sortedVerses.first {
                            proxy.scrollTo(firstVerse.id, anchor: .top)
                        }
                    }
                }
            }
        }
        .navigationTitle("\(chapter.book?.name ?? "") \(chapter.number)")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 8) {
                    // Previous/Next chapter navigation
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
                    
                    // Next chapter navigation
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
        .onAppear {
            performBackgroundSave()
        }
        .onDisappear {
            // Save any pending changes when leaving the view
            if pendingSave {
                try? modelContext.save()
                pendingSave = false
            }
        }
    }
}

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
                // Tool selection
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
                
                Divider()
                    .frame(height: 30)
                
                // Quick colors
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
                
                Divider()
                    .frame(height: 30)
                
                // Width
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

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Book.self,
            Chapter.self,
            Verse.self,
            Note.self,
            configurations: config
        )
        
        let book = Book(name: "Genesis", order: 1, testament: "OT")
        let chapter = Chapter(number: 1)
        let verse1 = Verse(number: 1, text: "In the beginning God created the heaven and the earth.", chapter: chapter)
        let verse2 = Verse(number: 2, text: "The earth was without form and void, and darkness was over the face of the deep. And the Spirit of God was hovering over the face of the waters.", chapter: chapter)
        chapter.verses = [verse1, verse2]
        
        return NavigationStack {
            ChapterView(chapter: chapter, onChapterChange: { _ in })
        }
        .modelContainer(container)
    } catch {
        return Text("Failed to create preview: \(error.localizedDescription)")
    }
}
