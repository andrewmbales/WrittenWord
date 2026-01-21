//
//  DrawingView.swift
//  WrittenWord
//
//  Created by Andrew Bales on 1/21/26.
//
import SwiftUI
import SwiftData
import PencilKit

struct DrawingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var canvas = PKCanvasView()
    @State private var drawing = PKDrawing()
    @State private var verseReference: String = ""
    
    var note: Note?
    var chapter: Chapter?
    var verse: Verse?
    
    // Initialize for editing an existing note
    init(note: Note) {
        self.note = note
        self._verseReference = State(initialValue: note.verseReference)
    }
    
    // Initialize for creating a new chapter note
    init(chapter: Chapter) {
        self.chapter = chapter
        self._verseReference = State(initialValue: "\(chapter.book?.name ?? "") \(chapter.number)")
    }
    
    // Initialize for creating a new verse note
    init(verse: Verse) {
        self.verse = verse
        self._verseReference = State(initialValue: "\(verse.chapter?.book?.name ?? "") \(verse.chapter?.number ?? 0):\(verse.number)")
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                if note == nil {
                    Text(verseReference)
                        .font(.headline)
                        .padding()
                }
                
                PencilKitCanvas(canvas: $canvas, drawing: $drawing)
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
                    .disabled(verseReference.isEmpty)
                }
            }
        }
    }
    
    private func saveDrawing() {
        do {
            if let note = note {
                // Update existing note
                note.drawing = drawing
                note.verseReference = verseReference
                note.updatedAt = Date()
            } else {
                // Create new note
                let newNote = Note(
                    title: verseReference,
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
            // Consider showing an error alert to the user
        }
    }
}

struct PencilKitCanvas: UIViewRepresentable {
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