//
//  FullPageDrawingView.swift
//  WrittenWord
//
//  Created by Andrew Bales on 1/21/26.
//  FIXED: Drawing changes now sync back from canvas so Save actually persists
//
import SwiftUI
import SwiftData
import PencilKit

struct FullPageDrawingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage("colorTheme") private var colorTheme: ColorTheme = .system

    @State private var canvas = PKCanvasView()
    @State private var drawing = PKDrawing()
    @State private var verseReference: String = ""
    @State private var noteTitle: String = ""
    @State private var hasUnsavedChanges = false
    @State private var showDiscardAlert = false

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
                    .onChange(of: noteTitle) { _, _ in
                        hasUnsavedChanges = true
                    }
            }

            FullPagePencilKitCanvas(
                canvas: $canvas,
                drawing: $drawing,
                onDrawingChanged: {
                    hasUnsavedChanges = true
                }
            )
            .onAppear {
                if let note = note {
                    drawing = note.drawing
                }
            }

            // Save button pinned at bottom
            Button {
                saveDrawing()
            } label: {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save Note")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(hasUnsavedChanges ? Color.blue : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!hasUnsavedChanges)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .background(colorTheme.backgroundColor)
        .navigationTitle(note == nil ? "New Note" : "Edit Note")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    if hasUnsavedChanges {
                        showDiscardAlert = true
                    } else {
                        dismiss()
                    }
                }
            }

            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    saveDrawing()
                    dismiss()
                }
            }
        }
        .alert("Unsaved Changes", isPresented: $showDiscardAlert) {
            Button("Discard", role: .destructive) {
                dismiss()
            }
            Button("Keep Editing", role: .cancel) { }
        } message: {
            Text("You have unsaved changes. Are you sure you want to discard them?")
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
            hasUnsavedChanges = false

            #if DEBUG
            print("✅ Full page note saved successfully")
            #endif
        } catch {
            print("Failed to save note: \(error.localizedDescription)")
        }
    }
}

// MARK: - PencilKit Canvas with delegate sync
struct FullPagePencilKitCanvas: UIViewRepresentable {
    @Binding var canvas: PKCanvasView
    @Binding var drawing: PKDrawing
    var onDrawingChanged: (() -> Void)?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        canvas.drawing = drawing
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: .black, width: 1)
        canvas.delegate = context.coordinator
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Only update if the drawing changed externally (e.g., onAppear loading)
        if uiView.drawing != drawing {
            context.coordinator.suppressSync = true
            uiView.drawing = drawing
            context.coordinator.suppressSync = false
        }
    }

    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: FullPagePencilKitCanvas
        var suppressSync = false

        init(_ parent: FullPagePencilKitCanvas) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !suppressSync else { return }
            parent.drawing = canvasView.drawing
            parent.onDrawingChanged?()
        }
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
