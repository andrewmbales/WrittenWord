//
//  ContentView.swift
//  WrittenWord
//
//  Created by Andrew Bales on 1/21/26.
//
import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainView()
    }
}
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Book.self, 
        Chapter.self, 
        Verse.self, 
        Note.self,
        configurations: config
    )
    
    return ContentView()
        .modelContainer(container)
}