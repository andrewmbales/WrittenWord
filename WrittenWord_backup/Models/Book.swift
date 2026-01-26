//
//  Book.swift
//  WrittenWord
//
//  Created by Andrew Bales on 1/21/26.
//
import Foundation
import SwiftData

@Model

final class Book: Identifiable {
    var id: UUID
    var name: String
    var testament: String // "OT" or "NT"
    var order: Int
    
    @Relationship(deleteRule: .cascade)
    var chapters: [Chapter] = []
    
    init(name: String, order: Int, testament: String) {
        self.id = UUID()
        self.name = name
        self.order = order
        self.testament = testament
    }
    
    var abbreviation: String {
        String(name.prefix(3)).uppercased()
    }
    
    var displayName: String {
        "\(name) (\(abbreviation))"
    }
}
