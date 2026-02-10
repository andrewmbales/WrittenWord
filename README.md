# WrittenWord

> A comprehensive iPad Bible study application combining modern SwiftUI development with advanced biblical scholarship tools

WrittenWord is an offline-first Bible study platform designed specifically for iPad, featuring text highlighting, handwritten annotations via Apple Pencil, note-taking, bookmarks, and advanced interlinear word lookup for Greek and Hebrew original language study.

## Features

### 📖 Bible Reading
- **Complete KJV Text**: Full King James Version Bible with all 66 books
- **Offline-First**: All biblical text stored locally using SwiftData
- **Smooth Navigation**: NavigationSplitView architecture with sidebar navigation
- **Chapter-by-Chapter Reading**: Optimized verse rendering with lazy loading
- **Multiple Translation Support** (Planned): ESV, NASB, and other translations through proper licensing agreements

### ✍️ Study Tools
- **Text Highlighting**: Select and highlight verses with customizable colors
- **PencilKit Annotations**: Full-page handwritten notes and drawings with Apple Pencil
- **Note-Taking**: Create detailed study notes linked to specific verses or chapters
- **Bookmarks**: Save and organize important passages with categories and colors
- **Search Functionality**: Fast, comprehensive search across the entire Bible with filters and scoping

### 🔍 Interlinear Word Lookup
- **Greek & Hebrew Analysis**: Tap any word to view original language information
- **Word Details**:
  - Original text (Greek/Hebrew)
  - Transliteration
  - Strong's concordance numbers
  - English gloss/definition
  - Detailed morphological analysis (part of speech, tense, mood, voice, case, etc.)
  - Word position tracking within verses
- **Current Coverage**: Sample data for John 1:1-14 (Greek), Genesis 1:1-5, and Psalm 23:1-3 (Hebrew)
- **Data Source**: STEPBible TAGNT (Translators Amalgamated Greek New Testament)

### 📊 Study Insights
- **Highlight Statistics**: Visual analytics of your highlighting patterns
- **Book Distribution**: Charts showing where you've focused your study
- **Search Analytics**: Understand your research patterns

## Technical Architecture

### Technology Stack
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Persistent storage with relationship management
- **PencilKit**: Apple Pencil integration for handwritten annotations
- **MVVM Pattern**: Clean separation of concerns with ViewModels

### Database Schema

```swift
@Model Book
├── id: UUID
├── name: String
├── testament: String (OT/NT)
├── order: Int
└── chapters: [Chapter]

@Model Chapter
├── id: UUID
├── number: Int
├── title: String?
├── book: Book
├── verses: [Verse]
└── notes: [Note]

@Model Verse
├── id: UUID
├── number: Int
├── text: String
├── version: String
├── chapter: Chapter
├── notes: [Note]
└── words: [Word]

@Model Word (Interlinear)
├── id: UUID
├── originalText: String
├── transliteration: String
├── strongsNumber: String
├── gloss: String
├── morphology: String
├── wordIndex: Int
├── startPosition: Int
├── endPosition: Int
├── translatedText: String
├── language: String
└── verse: Verse

@Model Note
├── id: UUID
├── title: String
├── content: String
├── drawing: PKDrawing
├── verseReference: String
├── isMarginNote: Bool
├── chapter: Chapter?
└── verse: Verse?

@Model Highlight
├── id: UUID
├── verseId: UUID
├── startIndex: Int
├── endIndex: Int
├── color: Color
├── text: String
└── verse: Verse

@Model Bookmark
├── id: UUID
├── title: String
├── category: String
├── color: String
├── notes: String
├── createdAt: Date
├── isPinned: Bool
├── verse: Verse?
└── chapter: Chapter?
```

### Project Structure

```
WrittenWord/
├── Models/
│   ├── Book.swift
│   ├── Chapter.swift
│   ├── Verse.swift
│   ├── Word.swift
│   ├── Note.swift
│   ├── Highlight.swift
│   ├── Bookmark.swift
│   ├── SearchResult.swift
│   └── LexiconEntry.swift
├── Views/
│   ├── MainView.swift
│   ├── SidebarView.swift
│   ├── ChapterView.swift
│   ├── SearchView.swift
│   ├── NotebookView.swift
│   ├── BookmarksView.swift
│   ├── HighlightStatsView.swift
│   ├── SettingsView.swift
│   └── Components/
│       ├── InterlinearLookupView.swift
│       ├── HighlightPalette.swift
│       └── FullPageAnnotationCanvas.swift
├── ViewModels/
│   └── ChapterViewModel.swift
├── Services/
│   ├── InterlinearSeeder.swift
│   ├── LexiconService.swift
│   └── MorphologyParser.swift
├── Resources/
│   ├── Data/
│   │   └── kjv.json
│   └── interlinear/
│       ├── matthew.json
│       ├── mark.json
│       ├── luke.json
│       ├── john.json
│       └── ... (all NT books)
└── Utilities/
    ├── DebugConfig.swift
    └── ColorExtensions.swift
```

## Getting Started

### Requirements
- **iOS/iPadOS**: 17.0 or later
- **Xcode**: 15.0 or later
- **Swift**: 5.9 or later
- **Device**: iPad (optimized for iPad use with Apple Pencil)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/WrittenWord.git
   cd WrittenWord
   ```

2. **Open in Xcode**
   ```bash
   open WrittenWord.xcodeproj
   ```

3. **Verify Bundle Resources**
   - Ensure `kjv.json` is in the "Copy Bundle Resources" build phase
   - Verify interlinear JSON files are included (if using interlinear features)
   - Check that resource folders use "folder references" (blue folders) not "groups" (yellow folders)

4. **Build and Run**
   - Select an iPad simulator or device
   - Press `Cmd + R` to build and run
   - First launch will seed the database (~30 seconds for full KJV text)

### First Launch

On first launch, WrittenWord will:
1. Seed the complete KJV Bible text (66 books, 1,189 chapters, 31,102 verses)
2. Seed sample interlinear data for demonstration (John 1:1-14, Genesis 1:1-5, Psalm 23:1-3)
3. Create the SwiftData database schema
4. Initialize default settings

This process takes approximately 30-60 seconds depending on device performance.

## Data Sources & Licensing

### Bible Text
- **Current**: King James Version (KJV) - Public Domain
- **Planned**: 
  - ESV (English Standard Version) - Requires licensing from Crossway
  - NASB (New American Standard Bible) - Requires licensing from Lockman Foundation
  - Other translations pending licensing agreements

### Interlinear Data
- **Greek New Testament**: STEPBible TAGNT (Translators Amalgamated Greek New Testament)
  - Source: [STEPBible-Data GitHub](https://github.com/STEPBible/STEPBible-Data)
  - License: Creative Commons Attribution 4.0 International
- **Hebrew Old Testament**: In development
  - Planned source: Westminster Leningrad Codex or Open Scriptures Hebrew Bible

### Future Data Sources
- **Cross-References**: Treasury of Scripture Knowledge (500,000+ cross-references)
- **Alignment Data**: Clear Bible Macula Greek for improved word-level translation accuracy
- **Lexicons**: Integration of Strong's Concordance, BDAG, and other scholarly lexicons

## Development Roadmap

### Current Status (v1.0 In Development)
- ✅ Core Bible reading interface
- ✅ Text highlighting with multiple colors
- ✅ PencilKit handwritten annotations
- ✅ Note-taking system
- ✅ Bookmark management
- ✅ Global search functionality
- ✅ Basic interlinear lookup (sample data)
- ✅ SwiftData persistence layer
- 🚧 Performance optimization
- 🚧 UI/UX refinements

### Planned Features (v1.1+)
- ⏳ **Full Interlinear Coverage**: Complete Greek NT and Hebrew OT
- ⏳ **Multiple Translations**: ESV, NASB, and others
- ⏳ **Cross-References**: Treasury of Scripture Knowledge integration
- ⏳ **iCloud Sync**: Sync notes, highlights, and bookmarks across devices
- ⏳ **Study Plans**: Guided reading plans and devotionals
- ⏳ **Enhanced Search**: Advanced Boolean operators and regex support
- ⏳ **Export Functionality**: Export notes and highlights to PDF/Markdown
- ⏳ **Theme Customization**: Dark mode, sepia, and custom color schemes
- ⏳ **Gesture Navigation**: Swipe between chapters
- ⏳ **Verse Comparison**: Side-by-side translation comparison
- ⏳ **Audio Bible**: Integrated audio playback
- ⏳ **Commentary Integration**: Matthew Henry, Barnes' Notes, etc.

### Technical Improvements
- ⏳ **Database Optimization**: Indexing for faster search and lookup
- ⏳ **Memory Management**: Better handling of large chapters
- ⏳ **Background Processing**: Async/await for heavy operations
- ⏳ **Testing Suite**: Unit and UI tests for critical functionality
- ⏳ **Accessibility**: VoiceOver support and Dynamic Type
- ⏳ **Localization**: Multi-language UI support

## Performance Considerations

### Optimizations Implemented
- **Lazy Loading**: Verses loaded on-demand to reduce memory footprint
- **Caching Strategy**: Highlights and interlinear data cached in ViewModels
- **Predicated Queries**: SwiftData queries use predicates to minimize data fetching
- **Async Operations**: Heavy operations (search, seeding) run asynchronously
- **SwiftUI Best Practices**: Minimized view redraws, proper state management

### Known Limitations
- Interlinear data currently limited to sample verses (full coverage in development)
- Text selection for highlighting uses UITextView (performance trade-offs for complex selection)
- Large chapters (150+ verses) may have slight lag on older iPads
- First launch seed time can be slow on devices with limited storage

## Contributing

Contributions are welcome! Please follow these guidelines:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Follow Swift style guidelines** (SwiftLint configuration provided)
4. **Write descriptive commit messages**
5. **Test thoroughly** on both simulator and device
6. **Submit a pull request**

### Areas Needing Help
- **Interlinear Data Expansion**: Converting additional biblical texts to JSON format
- **Translation Licensing**: Assistance with publisher licensing agreements
- **UI/UX Design**: Interface improvements and accessibility enhancements
- **Testing**: Comprehensive test coverage
- **Documentation**: User guides and developer documentation
- **Localization**: Translations for international users

## Known Issues & Troubleshooting

### Text Selection Not Working
- **Issue**: Highlighting text selection may not respond
- **Fix**: Ensure UITextView delegate is properly configured and tool selection is set to `.none`

### Database Seeding Errors
- **Issue**: "No books found" or "Seeding failed"
- **Fix**: Check that `kjv.json` is in "Copy Bundle Resources" build phase. Delete app and reinstall to trigger fresh seed.

### Interlinear Lookup Shows No Data
- **Issue**: Tapping words doesn't show Greek/Hebrew information
- **Fix**: Verify interlinear JSON files are bundled. Currently only sample data available for John 1, Genesis 1, Psalm 23.

### Performance Issues
- **Issue**: Lag when scrolling through chapters
- **Fix**: Close other apps, restart device, or reduce highlight count in large chapters

### Build Errors
- **Issue**: "Cannot find type 'X' in scope" or duplicate symbol errors
- **Fix**: Clean build folder (`Cmd + Shift + K`), delete derived data, rebuild

## License

### Code License
WrittenWord application code is licensed under the MIT License. See [LICENSE](LICENSE) file for details.

### Content Licenses
- **KJV Bible Text**: Public Domain
- **Interlinear Data**: Creative Commons Attribution 4.0 International (CC BY 4.0)
- **Future Translations**: Subject to individual publisher licensing agreements

### Third-Party Acknowledgments
- STEPBible-Data for Greek New Testament interlinear data
- Apple Inc. for PencilKit and SwiftUI frameworks
- All biblical text publishers and data providers

## Contact & Support

- **Developer**: Andrew Bales
- **Project Repository**: [GitHub](https://github.com/yourusername/WrittenWord)
- **Issues**: [GitHub Issues](https://github.com/yourusername/WrittenWord/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/WrittenWord/discussions)

## Acknowledgments

Special thanks to:
- **STEPBible** for providing high-quality interlinear Greek data
- **Open Scriptures** community for biblical text resources
- **Apple Developer Community** for SwiftUI and PencilKit support
- **Beta Testers** for feedback and bug reports
- **Contributors** who have helped shape this project

---

**Note**: WrittenWord is an independent project and is not affiliated with or endorsed by any Bible translation publisher, biblical scholarship organization, or religious institution. All trademarks and copyrights belong to their respective owners.

## Appendix: Interlinear Data Format

For developers working with the interlinear JSON format:

```json
{
  "book": "John",
  "verses": [
    {
      "chapter": 1,
      "verse": 1,
      "words": [
        {
          "originalText": "Ἐν",
          "transliteration": "En",
          "strongsNumber": "G1722",
          "gloss": "In",
          "morphology": "PREP",
          "wordIndex": 0,
          "startPosition": 0,
          "endPosition": 2,
          "translatedText": "In",
          "language": "grk"
        }
      ]
    }
  ]
}
```

### Morphology Codes
- **Greek**: Standard morphological tagging (e.g., `V-AAI-3S` = Verb, Aorist, Active, Indicative, 3rd person, Singular)
- **Hebrew**: Westminster Hebrew Morphology coding system

For complete morphology documentation, see `/Docs/MorphologyCodes.md` (if available).
