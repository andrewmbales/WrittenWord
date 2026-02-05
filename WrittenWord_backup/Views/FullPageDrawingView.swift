//
//  FullPageDrawingView.swift
//  WrittenWord
//
//  Created by Andrew Bales on 1/21/26.
//
import SwiftUI
import SwiftData
import PencilKit

struct FullPageDrawingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var canvas = PKCanvasView()
    @State private var drawing = PKDrawing()
    @State private var verseReference: String = ""
    @State private var noteTitle: String = ""
    
    var note: Note?
    var chapter: Chapter?
    var verse: Verse?
    
    init(note: Note) {
        self.note = note
        self._verseReference = State(initialValue: note.verseReference)
        self._noteTitle = State(initialValue: note.title)
    }
    
    init(chapter: Chapter) {
        self.chapter = chapter
        self._verseReference = State(initialValue: "\(chapter.book?.name ?? "") \(chapter.number)")
    }
    
    init(verse: Verse) {
        self.verse = verse
        self._verseReference = State(initialValue: "\(verse.chapter?.book?.name ?? "") \(verse.chapter?.number ?? 0):\(verse.number)")
    }
    
    var body: some View {
        VStack {
            if note == nil {
                Text(verseReference)
                    .font(.headline)
                    .padding()
            } else {
                TextField("Note Title", text: $noteTitle)
                    .font(.headline)
                    .textFieldStyle(.plain)
                    .padding()
            }
            
            FullPagePencilKitCanvas(canvas: $canvas, drawing: $drawing)
                .onAppear {
                    if let note = note {
                        drawing = note.drawing
                    }
                }
        }
        .navigationTitle(note == nil ? "New Note" : "Edit Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveDrawing()
                    dismiss()
                }
            }
        }
    }
    
    private func saveDrawing() {
        do {
            if let note = note {
                note.drawing = drawing
                note.verseReference = verseReference
                note.title = noteTitle.isEmpty ? verseReference : noteTitle
                note.updatedAt = Date()
            } else {
                let title = noteTitle.isEmpty ? verseReference : noteTitle
                let newNote = Note(
                    title: title,
                    content: "",
                    drawing: drawing,
                    verseReference: verseReference,
                    isMarginNote: false,
                    chapter: chapter,
                    verse: verse
                )
                modelContext.insert(newNote)
            }
            
            try modelContext.save()
        } catch {
            print("Failed to save note: \(error.localizedDescription)")
        }
    }
}

struct FullPagePencilKitCanvas: UIViewRepresentable {
    @Binding var canvas: PKCanvasView
    @Binding var drawing: PKDrawing
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawing = drawing
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: .black, width: 1)
        return canvas
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.drawing = drawing
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try? ModelContainer(
        for: Book.self,
        Chapter.self,
        Verse.self,
        Note.self,
        configurations: config
    )

    if let container {
        let book = Book(name: "Genesis", order: 1, testament: "OT")
        let chapter = Chapter(number: 1)
        chapter.book = book
        book.chapters = [chapter]

        let verse = Verse(number: 1, text: "In the beginning, God created the heavens and the earth.", chapter: chapter)
        chapter.verses = [verse]

        return NavigationStack {
            FullPageDrawingView(chapter: chapter)
        }
        .modelContainer(container)
    } else {
        return Text("Failed to create preview model container")
    }
}
