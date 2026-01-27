import SwiftUI
import SwiftData

struct ChapterDestination: View {
    @Environment(\.modelContext) private var modelContext
    let chapterID: UUID

    @State private var chapter: Chapter?

    var body: some View {
        Group {
            if let chapter {
                ChapterView(
                    chapter: chapter,
                    onChapterChange: { newChapter in
                        // Keep navigation state in sync if needed by parent
                        // This view focuses on rendering the chapter by id
                    }
                )
                .id(chapter.id)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            } else {
                ContentUnavailableView(
                    "Loading Chapter",
                    systemImage: "hourglass",
                    description: Text("Please wait...")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .task { await loadChapter() }
            }
        }
    }

    @MainActor
    private func loadChapter() async {
        do {
            var descriptor = FetchDescriptor<Chapter>()
            descriptor.predicate = #Predicate { $0.id == chapterID }
            descriptor.fetchLimit = 1
            if let found = try modelContext.fetch(descriptor).first {
                self.chapter = found
            }
        } catch {
            // Silent fail renders unavailable view
        }
    }
}
