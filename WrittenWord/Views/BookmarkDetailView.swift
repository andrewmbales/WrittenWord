//
//  BookmarkDetailView.swift
//  WrittenWord
//
//  Created by Andrew Bales on 2/6/26.
//


import SwiftUI

struct BookmarkDetailView: View {
    let verse: Verse
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Bookmark Detail")
                    .font(.headline)
                Text(verse.text)
                    .padding()
            }
            .navigationTitle("Bookmark")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}