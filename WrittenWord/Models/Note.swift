//
//  Note.swift
//  WrittenWord
//
//  Created by Andrew Bales on 1/21/26.
//
import Foundation
import SwiftData
import PencilKit

@Model
final class Note: Identifiable {
    var id: UUID
    var title: String
    var content: String
    var drawingData: Data
    var verseReference: String  // Added back the missing property
    var isMarginNote: Bool
    var createdAt: Date
    var updatedAt: Date
    var chapter: Chapter?
    var verse: Verse?
    
    init(title: String = "New Note", 
         content: String = "",
         drawing: PKDrawing = PKDrawing(),
         verseReference: String = "",
         isMarginNote: Bool = false,
         chapter: Chapter? = nil,
         verse: Verse? = nil) {
        
        self.id = UUID()
        self.title = title
        self.content = content
        self.drawingData = drawing.dataRepresentation()
        self.verseReference = verseReference
        self.isMarginNote = isMarginNote
        self.createdAt = Date()
        self.updatedAt = Date()
        self.chapter = chapter
        self.verse = verse
    }
    
    var drawing: PKDrawing {
        get { (try? PKDrawing(data: drawingData)) ?? PKDrawing() }
        set { 
            drawingData = newValue.dataRepresentation()
            updatedAt = Date()
        }
    }
    
    var reference: String {
        if let verse = verse {
            return verse.reference
        } else if let chapter = chapter {
            return chapter.reference
        }
        return verseReference.isEmpty ? title : verseReference
    }
}