//
//  NotebookView.swift
//  WrittenWord
//
//  Created by Andrew Bales on 1/21/26.
//
import SwiftUI
import PencilKit
import SwiftData

struct NotebookView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.updatedAt, order: .reverse) private var notes: [Note]
    @State private var showingNewNote = false
    
    var body: some View {
        NavigationStack {
            Group {
                if notes.isEmpty {
                    ContentUnavailableView(
                        "No Notes Yet",
                        systemImage: "note.text",
                        description: Text("Tap the + button to create your first note")
                    )
                } else {
                    List {
                        ForEach(notes) { note in
                            NavigationLink(destination: DrawingView(note: note)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(note.verseReference)
                                        .font(.headline)
                                    Text("Last updated: \(note.updatedAt.formatted())")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .onDelete(perform: deleteNotes)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("My Notebook")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewNote = true
                    } label: {
                        Label("New Note", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewNote) {
                NavigationStack {
                    let newNote = Note(verseReference: "Untitled Note")
                    DrawingView(note: newNote)
                }
            }
        }
    }
    
    private func deleteNotes(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(notes[index])
            }
        }
    }
}

#Preview {
    NotebookView()
        .modelContainer(for: [Note.self], inMemory: true)
}