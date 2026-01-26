import Foundation
import SwiftUI

final class AppNavigationState: ObservableObject {
    enum Section: Hashable {
        case bible
        case search
        case notebook
        case highlights
        case bookmarks
        case statistics
        case settings
    }

    @Published var selectedSection: Section? = .bible
    @Published var selectedChapter: Chapter?
}
