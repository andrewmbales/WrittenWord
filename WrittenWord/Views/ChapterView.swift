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
        try? modelContext.save()
        return newNote
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
                    }
                    .padding(.vertical)
                }
            }
        }
        .navigationTitle("\(chapter.book?.name ?? "") \(chapter.number)")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
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