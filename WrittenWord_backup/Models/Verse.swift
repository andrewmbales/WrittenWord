//
//  Verse.swift
//  WrittenWord
//
//  Created by Andrew Bales on 1/21/26.
//
import Foundation
import SwiftData

@Model
final class Verse: Identifiable {
    var id: UUID
    var number: Int
    var text: String
    var version: String
    var chapter: Chapter?
    var notes: [Note] = []
    
    init(number: Int, 
         text: String, 
         version: String = "KJV", 
         chapter: Chapter? = nil) {
        self.id = UUID()
        self.number = number
        self.text = text
        self.version = version
        self.chapter = chapter
    }
    
    var reference: String {
        guard let chapter = chapter, let book = chapter.book else {
            return "Verse \(number)"
        }
        return "\(book.name) \(chapter.number):\(number)"
    }
    
    var formattedText: String {
        "\(number) \(text)"
    }
}
