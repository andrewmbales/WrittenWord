import SwiftUI
import SwiftData

struct ChapterView: View {
    let chapter: Chapter
    let onChapterChange: (Chapter) -> Void

    var body: some View {
        ChapterView_Optimized(chapter: chapter, onChapterChange: onChapterChange)
    }
}
