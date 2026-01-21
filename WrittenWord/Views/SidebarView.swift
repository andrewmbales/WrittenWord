//
//  SidebarView.swift
//  WrittenWord
//
//  Created by Andrew Bales on 1/21/26.
//
import SwiftUI
import SwiftData

struct SidebarView: View {
    @Query private var books: [Book]
    @Binding var selectedBook: Book?
    @State private var selectedView: SidebarViewType? = .bible
    
    var body: some View {
        let _ = print("SidebarView - Books count: \(books.count)")
        List(selection: $selectedView) {
            Section("Navigation") {
                NavigationLink(value: SidebarViewType.bible) {
                    Label("Bible", systemImage: "book.closed")
                }
                
                NavigationLink(value: SidebarViewType.notebook) {
                    Label("Notebook", systemImage: "note.text")
                }
                
                NavigationLink(destination: SettingsView()) {
                    Label("Settings", systemImage: "gear")
                }
            }
            
            if selectedView == .bible {
                Section("Old Testament") {
                    ForEach(books.filter { $0.testament == "OT" }.sorted { $0.order < $1.order }) { book in
                        NavigationLink(book.name, value: SidebarViewType.book(book))
                    }
                }
                
                Section("New Testament") {
                    ForEach(books.filter { $0.testament == "NT" }.sorted { $0.order < $1.order }) { book in
                        NavigationLink(book.name, value: SidebarViewType.book(book))
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Written Word")
        .onChange(of: selectedView) { oldValue, newValue in
            if case .book(let book) = newValue {
                selectedBook = book
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Book.self,
        Chapter.self,
        Note.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    
    let book = Book(name: "Genesis", order: 1, testament: "OT")
    container.mainContext.insert(book)
    
    return SidebarView(selectedBook: .constant(nil))
        .modelContainer(container)
}
