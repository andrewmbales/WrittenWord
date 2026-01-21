//
//  Chapter.swift
//  WrittenWord
//
//  Created by Andrew Bales on 1/21/26.
//
import Foundation
import SwiftData
@Model
final class Chapter: Identifiable {
    var id: UUID
    var number: Int
    var title: String?
    
    // Relationship to Book
    @Relationship(inverse: \Book.chapters)
    var book: Book?
    
    @Relationship(deleteRule: .cascade)
    var verses: [Verse] = []
    
    @Relationship(deleteRule: .cascade)
    var notes: [Note] = []
    
    init(number: Int, title: String? = nil, book: Book? = nil) {
        self.id = UUID()
        self.number = number
        self.title = title
        self.book = book
    }
    
    var reference: String {
        book.map { "\($0.name) \(number)" } ?? "Chapter \(number)"
    }
}
