//
//  SidebarView.swift
//  WrittenWord
//
//  Enhanced with better visual hierarchy
//
import SwiftUI
import SwiftData

struct SidebarView: View {
    @Query(sort: \Book.order) private var books: [Book]
    @Binding var selectedBook: Book?
    @State private var selectedView: SidebarViewType? = .bible
    @State private var expandedTestament: String? = "OT"
    
    var oldTestamentBooks: [Book] {
        books.filter { $0.testament == "OT" }.sorted { $0.order < $1.order }
    }
    
    var newTestamentBooks: [Book] {
        books.filter { $0.testament == "NT" }.sorted { $0.order < $1.order }
    }
    
    var body: some View {
        List(selection: $selectedView) {
            Section {
                NavigationLink(value: SidebarViewType.bible) {
                    Label {
                        Text("Bible")
                            .font(.headline)
                    } icon: {
                        Image(systemName: "book.closed.fill")
                            .foregroundStyle(.blue)
                    }
                }
                
                NavigationLink(value: SidebarViewType.notebook) {
                    Label {
                        Text("Notebook")
                            .font(.headline)
                    } icon: {
                        Image(systemName: "note.text")
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            if selectedView == .bible {
                Section {
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedTestament == "OT" },
                            set: { expandedTestament = $0 ? "OT" : nil }
                        )
                    ) {
                        ForEach(oldTestamentBooks) { book in
                            NavigationLink(value: SidebarViewType.book(book)) {
                                HStack {
                                    Text(book.name)
                                    Spacer()
                                    Text("\(book.chapters.count)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.secondary.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    } label: {
                        Label {
                            Text("Old Testament")
                                .font(.subheadline.bold())
                        } icon: {
                            Image(systemName: "book")
                                .foregroundStyle(.purple)
                        }
                    }
                    
                    DisclosureGroup(
                        isExpanded: Binding(
                            get: { expandedTestament == "NT" },
                            set: { expandedTestament = $0 ? "NT" : nil }
                        )
                    ) {
                        ForEach(newTestamentBooks) { book in
                            NavigationLink(value: SidebarViewType.book(book)) {
                                HStack {
                                    Text(book.name)
                                    Spacer()
                                    Text("\(book.chapters.count)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(Color.secondary.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                    } label: {
                        Label {
                            Text("New Testament")
                                .font(.subheadline.bold())
                        } icon: {
                            Image(systemName: "book")
                                .foregroundStyle(.indigo)
                        }
                    }
                }
            }
            
            Section {
                NavigationLink(destination: SettingsView()) {
                    Label {
                        Text("Settings")
                    } icon: {
                        Image(systemName: "gear")
                            .foregroundStyle(.gray)
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
    
    let genesis = Book(name: "Genesis", order: 1, testament: "OT")
    genesis.chapters = [Chapter(number: 1), Chapter(number: 2)]
    container.mainContext.insert(genesis)
    
    let matthew = Book(name: "Matthew", order: 40, testament: "NT")
    matthew.chapters = [Chapter(number: 1)]
    container.mainContext.insert(matthew)
    
    return SidebarView(selectedBook: .constant(nil))
        .modelContainer(container)
}
