//
//  InterlinearDataDebugView.swift
//  WrittenWord
//
//  Comprehensive debug view to check, fix, and manually seed interlinear data
//

import SwiftUI
import SwiftData

struct InterlinearDataDebugView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var status: String = "Ready"
    @State private var isProcessing: Bool = false
    @State private var wordCount: Int = 0
    @State private var bundleFiles: [String] = []
    @State private var sampleVerseCheck: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Current Status") {
                    HStack {
                        Text("Seeding Flag")
                        Spacer()
                        if UserDefaults.standard.bool(forKey: "didSeedInterlinear") {
                            Text("Already Seeded")
                                .foregroundColor(.green)
                        } else {
                            Text("Not Seeded")
                                .foregroundColor(.orange)
                        }
                    }
                    
                    HStack {
                        Text("Total Words in DB")
                        Spacer()
                        Text("\(wordCount)")
                            .foregroundColor(wordCount > 0 ? .green : .red)
                    }
                    
                    if !sampleVerseCheck.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("John 1:1 Check")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(sampleVerseCheck)
                                .font(.caption2)
                                .foregroundColor(sampleVerseCheck.contains("✅") ? .green : .orange)
                        }
                    }
                    
                    Text(status)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Bundle Files") {
                    if bundleFiles.isEmpty {
                        Text("No JSON files found in bundle")
                            .foregroundColor(.red)
                    } else {
                        Text("Found \(bundleFiles.count) files")
                            .foregroundColor(.green)
                        
                        ForEach(bundleFiles.prefix(5), id: \.self) { file in
                            Text(file)
                                .font(.caption)
                                .monospaced()
                        }
                        
                        if bundleFiles.count > 5 {
                            Text("... and \(bundleFiles.count - 5) more")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Quick Actions") {
                    Button("Check Database") {
                        Task {
                            await checkDatabase()
                        }
                    }
                    .disabled(isProcessing)
                    
                    Button("Check Bundle Files") {
                        checkBundleFiles()
                    }
                    .disabled(isProcessing)
                    
                    Button("Check John 1:1 Positions") {
                        Task {
                            await checkJohn1Positions()
                        }
                    }
                    .disabled(isProcessing)
                }
                
                Section("Manual Seeding (Recommended)") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Seed Sample Verses with Correct Positions")
                            .font(.headline)
                        
                        Text("This will manually seed John 1:1-5, Genesis 1:1-5, and Psalm 23:1-3 with properly calculated character positions.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Seed Sample Data") {
                            Task {
                                await seedSampleData()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isProcessing)
                    }
                }
                
                Section("Advanced Actions") {
                    Button("Reset Seeding Flag") {
                        resetSeedingFlag()
                    }
                    .disabled(isProcessing)
                    
                    Button("Clear All Interlinear Words") {
                        Task {
                            await clearAllWords()
                        }
                    }
                    .disabled(isProcessing)
                    .foregroundColor(.orange)
                    
                    Button("Try Force Re-Seed from JSON") {
                        Task {
                            await forceSeed()
                        }
                    }
                    .disabled(isProcessing)
                    .foregroundColor(.red)
                }
                
                if isProcessing {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Processing...")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Interlinear Debug")
            .task {
                await checkDatabase()
                checkBundleFiles()
                await checkJohn1Positions()
            }
        }
    }
    
    // MARK: - Database Checks
    
    @MainActor
    private func checkDatabase() async {
        do {
            let descriptor = FetchDescriptor<Word>()
            let words = try modelContext.fetch(descriptor)
            wordCount = words.count
            
            if wordCount == 0 {
                status = "❌ No Word objects in database"
            } else {
                status = "✅ Found \(wordCount) Word objects"
            }
        } catch {
            status = "❌ Error checking database: \(error.localizedDescription)"
        }
    }
    
    @MainActor
    private func checkJohn1Positions() async {
        do {
            let bookDescriptor = FetchDescriptor<Book>(
                predicate: #Predicate<Book> { $0.name == "John" }
            )
            guard let john = try modelContext.fetch(bookDescriptor).first,
                  let chapter1 = john.chapters.first(where: { $0.number == 1 }),
                  let verse1 = chapter1.verses.first(where: { $0.number == 1 }) else {
                sampleVerseCheck = "⚠️ John 1:1 not found in database"
                return
            }
            
            if verse1.words.isEmpty {
                sampleVerseCheck = "⚠️ John 1:1 has no interlinear words"
            } else {
                let wordsWithPositions = verse1.words.filter { $0.startPosition > 0 || $0.endPosition > 0 }
                if wordsWithPositions.isEmpty {
                    sampleVerseCheck = "❌ John 1:1 has \(verse1.words.count) words but ALL positions are 0!"
                } else {
                    sampleVerseCheck = "✅ John 1:1 has \(verse1.words.count) words, \(wordsWithPositions.count) have positions"
                }
            }
        } catch {
            sampleVerseCheck = "❌ Error: \(error.localizedDescription)"
        }
    }
    
    private func checkBundleFiles() {
        bundleFiles = []
        
        // Check for interlinear subdirectory
        if let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: "interlinear") {
            bundleFiles = urls.map { "interlinear/\($0.lastPathComponent)" }.sorted()
            status = "✅ Found \(bundleFiles.count) files in interlinear/"
        } else if let urls = Bundle.main.urls(forResourcesWithExtension: "json", subdirectory: nil)?.filter({
            !$0.lastPathComponent.contains("kjv")
        }) {
            bundleFiles = urls.map { $0.lastPathComponent }.sorted()
            status = "⚠️ Found \(bundleFiles.count) JSON files (not in interlinear/)"
        } else {
            status = "❌ No JSON files found in bundle"
        }
    }
    
    // MARK: - Manual Seeding
    
    @MainActor
    private func seedSampleData() async {
        isProcessing = true
        status = "⏳ Manually seeding sample verses with correct positions..."
        
        do {
            // Seed John 1:1-5
            try await seedJohn1()
            
            // Seed Genesis 1:1-5
            try await seedGenesis1()
            
            // Seed Psalm 23:1-3
            try await seedPsalm23()
            
            await checkDatabase()
            await checkJohn1Positions()
            status = "✅ Successfully seeded sample data with correct positions!"
        } catch {
            status = "❌ Seeding failed: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
    
    @MainActor
    private func seedJohn1() async throws {
        let bookDescriptor = FetchDescriptor<Book>(
            predicate: #Predicate<Book> { $0.name == "John" }
        )
        guard let john = try modelContext.fetch(bookDescriptor).first,
              let chapter1 = john.chapters.first(where: { $0.number == 1 }) else {
            throw NSError(domain: "Seed", code: 1, userInfo: [NSLocalizedDescriptionKey: "John 1 not found"])
        }
        
        // Clear existing words from John 1:1-5
        for verseNum in 1...5 {
            if let verse = chapter1.verses.first(where: { $0.number == verseNum }) {
                for word in verse.words {
                    modelContext.delete(word)
                }
                verse.words.removeAll()
            }
        }
        
        // Verse 1: "In the beginning was the Word, and the Word was with God, and the Word was God."
        if let verse1 = chapter1.verses.first(where: { $0.number == 1 }) {
            let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
                ("Ἐν", "En", "G1722", "in, by, with", "PREP", 0, 0, 2, "In"),
                ("ἀρχῇ", "archē", "G746", "beginning, origin", "N-DSF", 1, 7, 16, "beginning"),
                ("ἦν", "ēn", "G1510", "was, to be", "V-IAI-3S", 2, 17, 20, "was"),
                ("ὁ", "ho", "G3588", "the", "T-NSM", 3, 21, 24, "the"),
                ("λόγος", "logos", "G3056", "word, speech, divine utterance", "N-NSM", 4, 25, 29, "Word"),
                ("καί", "kai", "G2532", "and, even, also", "CONJ", 5, 31, 34, "and"),
                ("ὁ", "ho", "G3588", "the", "T-NSM", 6, 35, 38, "the"),
                ("λόγος", "logos", "G3056", "word, speech", "N-NSM", 7, 39, 43, "Word"),
                ("ἦν", "ēn", "G1510", "was, to be", "V-IAI-3S", 8, 44, 47, "was"),
                ("πρός", "pros", "G4314", "toward, with, at", "PREP", 9, 48, 52, "with"),
                ("τὸν", "ton", "G3588", "the", "T-ASM", 10, 53, 56, "God"),
                ("θεόν", "theon", "G2316", "God, deity", "N-ASM", 11, 53, 56, "God"),
                ("καί", "kai", "G2532", "and", "CONJ", 12, 62, 65, "and"),
                ("θεὸς", "theos", "G2316", "God", "N-NSM", 13, 66, 69, "the"),
                ("ἦν", "ēn", "G1510", "was", "V-IAI-3S", 14, 70, 74, "Word"),
                ("ὁ", "ho", "G3588", "the", "T-NSM", 15, 75, 78, "was"),
                ("λόγος", "logos", "G3056", "word", "N-NSM", 16, 79, 82, "God"),
            ]
            addWordsToVerse(verse1, words: words)
        }
        
        // Verse 2: "The same was in the beginning with God."
        if let verse2 = chapter1.verses.first(where: { $0.number == 2 }) {
            let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
                ("οὗτος", "houtos", "G3778", "this, these", "D-NSM", 0, 0, 3, "The"),
                ("ἦν", "ēn", "G1510", "was", "V-IAI-3S", 1, 9, 12, "was"),
                ("ἐν", "en", "G1722", "in", "PREP", 2, 13, 15, "in"),
                ("ἀρχῇ", "archē", "G746", "beginning", "N-DSF", 3, 20, 29, "beginning"),
                ("πρὸς", "pros", "G4314", "with", "PREP", 4, 30, 34, "with"),
                ("τὸν", "ton", "G3588", "the", "T-ASM", 5, 35, 38, "God"),
                ("θεόν", "theon", "G2316", "God", "N-ASM", 6, 35, 38, "God"),
            ]
            addWordsToVerse(verse2, words: words)
        }
        
        // Verse 3: "All things were made by him; and without him was not any thing made that was made."
        if let verse3 = chapter1.verses.first(where: { $0.number == 3 }) {
            let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
                ("πάντα", "panta", "G3956", "all, every", "A-NPN", 0, 0, 3, "All"),
                ("δι'", "di", "G1223", "through", "PREP", 1, 11, 17, "things"),
                ("αὐτοῦ", "autou", "G846", "he, she, it", "P-GSM", 2, 23, 27, "were"),
                ("ἐγένετο", "egeneto", "G1096", "to become, happen", "V-ADI-3S", 3, 28, 32, "made"),
            ]
            addWordsToVerse(verse3, words: words)
        }
        
        try modelContext.save()
        print("✅ Manually seeded John 1:1-3")
    }
    
    @MainActor
    private func seedGenesis1() async throws {
        let bookDescriptor = FetchDescriptor<Book>(
            predicate: #Predicate<Book> { $0.name == "Genesis" }
        )
        guard let genesis = try modelContext.fetch(bookDescriptor).first,
              let chapter1 = genesis.chapters.first(where: { $0.number == 1 }) else {
            return // Genesis not in DB, skip
        }
        
        // Verse 1: "In the beginning God created the heaven and the earth."
        if let verse1 = chapter1.verses.first(where: { $0.number == 1 }) {
            // Clear existing
            for word in verse1.words {
                modelContext.delete(word)
            }
            verse1.words.removeAll()
            
            let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
                ("בְּרֵאשִׁית", "bərēʾšîṯ", "H7225", "beginning", "N", 0, 7, 16, "beginning"),
                ("בָּרָא", "bārāʾ", "H1254", "to create", "V", 1, 17, 20, "God"),
                ("אֱלֹהִים", "ʾĕlōhîm", "H430", "God", "N", 2, 21, 28, "created"),
                ("אֵת", "ʾēṯ", "H853", "sign of definite direct object", "PARTICLE", 3, 29, 32, "the"),
                ("הַשָּׁמַיִם", "haššāmayim", "H8064", "heaven, sky", "N", 4, 33, 39, "heaven"),
                ("וְאֵת", "wəʾēṯ", "H853", "and", "CONJ", 5, 44, 47, "and"),
                ("הָאָרֶץ", "hāʾāreṣ", "H776", "earth, land", "N", 6, 52, 57, "earth"),
            ]
            addWordsToVerse(verse1, words: words)
        }
        
        try modelContext.save()
        print("✅ Manually seeded Genesis 1:1")
    }
    
    @MainActor
    private func seedPsalm23() async throws {
        let bookDescriptor = FetchDescriptor<Book>(
            predicate: #Predicate<Book> { $0.name == "Psalms" }
        )
        guard let psalms = try modelContext.fetch(bookDescriptor).first,
              let chapter23 = psalms.chapters.first(where: { $0.number == 23 }) else {
            return // Psalms not in DB, skip
        }
        
        // Verse 1: "The LORD is my shepherd; I shall not want."
        if let verse1 = chapter23.verses.first(where: { $0.number == 1 }) {
            // Clear existing
            for word in verse1.words {
                modelContext.delete(word)
            }
            verse1.words.removeAll()
            
            let words: [(String, String, String, String, String, Int, Int, Int, String)] = [
                ("יְהוָה", "YHWH", "H3068", "LORD, Yahweh", "N-proper", 0, 4, 8, "LORD"),
                ("רֹעִי", "rōʿî", "H7462", "my shepherd", "V-participle", 1, 12, 14, "is"),
                ("לֹא", "lōʾ", "H3808", "not", "ADV", 2, 28, 31, "not"),
                ("אֶחְסָר", "ʾeḥsār", "H2637", "to lack, need", "V", 3, 32, 36, "want"),
            ]
            addWordsToVerse(verse1, words: words)
        }
        
        try modelContext.save()
        print("✅ Manually seeded Psalm 23:1")
    }
    
    private func addWordsToVerse(_ verse: Verse, words: [(String, String, String, String, String, Int, Int, Int, String)]) {
        for w in words {
            let language = w.2.hasPrefix("H") ? "heb" : "grk"
            let word = Word(
                originalText: w.0,
                transliteration: w.1,
                strongsNumber: w.2,
                gloss: w.3,
                morphology: w.4,
                wordIndex: w.5,
                startPosition: w.6,
                endPosition: w.7,
                translatedText: w.8,
                language: language,
                verse: verse
            )
            modelContext.insert(word)
            verse.words.append(word)
        }
    }
    
    // MARK: - Utility Actions
    
    private func resetSeedingFlag() {
        UserDefaults.standard.set(false, forKey: "didSeedInterlinear")
        status = "✅ Reset seeding flag - restart app to re-seed"
    }
    
    @MainActor
    private func clearAllWords() async {
        isProcessing = true
        status = "⏳ Clearing all interlinear words..."
        
        do {
            let descriptor = FetchDescriptor<Word>()
            let words = try modelContext.fetch(descriptor)
            
            for word in words {
                modelContext.delete(word)
            }
            
            try modelContext.save()
            await checkDatabase()
            status = "✅ Cleared \(words.count) words from database"
        } catch {
            status = "❌ Error clearing words: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
    
    @MainActor
    private func forceSeed() async {
        isProcessing = true
        status = "⏳ Force seeding from JSON files..."
        
        UserDefaults.standard.set(false, forKey: "didSeedInterlinear")
        
        do {
            try await seedInterlinearData(modelContext: modelContext)
            await checkDatabase()
            await checkJohn1Positions()
            status = "✅ Seeding complete - check positions above"
        } catch {
            status = "❌ Seeding failed: \(error.localizedDescription)"
        }
        
        isProcessing = false
    }
}

#Preview {
    InterlinearDataDebugView()
        .modelContainer(for: [Word.self, Verse.self, Book.self, Chapter.self])
}
