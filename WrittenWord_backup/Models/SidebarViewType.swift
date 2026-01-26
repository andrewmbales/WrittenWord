//
//  SidebarViewType.swift
//  WrittenWord
//
//  Created by Andrew Bales on 1/21/26.
//
import SwiftUI
import SwiftData

enum SidebarViewType: Hashable {
    case bible
    case notebook
    case book(Book)
    
    var title: String {
        switch self {
        case .bible: return "Bible"
        case .notebook: return "Notebook"
        case .book(let book): return book.name
        }
    }
}