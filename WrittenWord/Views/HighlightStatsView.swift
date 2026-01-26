//
//  HighlightStatsView.swift
//  WrittenWord
//
//  Phase 2: Highlight Statistics and Insights
//
import SwiftUI
import SwiftData
import Charts

struct HighlightStatsView: View {
    @Query private var allHighlights: [Highlight]
    
    var totalHighlights: Int {
        allHighlights.count
    }
    
    var highlightsByColor: [ColorCount] {
        let grouped = Dictionary(grouping: allHighlights) { $0.highlightColor.toHex() }
        
        return grouped.map { hex, highlights in
            ColorCount(
                color: Color(hex: hex) ?? .yellow,
                colorName: matchColorName(hex: hex),
                count: highlights.count
            )
        }
        .sorted { $0.count > $1.count }
    }
    
    var highlightsByBook: [BookCount] {
        let grouped = Dictionary(grouping: allHighlights) { highlight -> String in
            highlight.verse?.chapter?.book?.name ?? "Unknown"
        }
        
        return grouped.map { bookName, highlights in
            BookCount(bookName: bookName, count: highlights.count)
        }
        .sorted { $0.count > $1.count }
        .prefix(10)
        .map { $0 }
    }
    
    var mostHighlightedVerses: [(Verse, Int)] {
        let grouped = Dictionary(grouping: allHighlights) { $0.verse }
        
        return grouped.compactMap { verse, highlights -> (Verse, Int)? in
            guard let verse = verse else { return nil }
            return (verse, highlights.count)
        }
        .sorted { $0.1 > $1.1 }
        .prefix(5)
        .map { $0 }
    }
    
    var recentHighlights: [Highlight] {
        allHighlights
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(5)
            .map { $0 }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Overview cards
                    overviewSection
                    
                    Divider()
                    
                    // Color distribution
                    if !highlightsByColor.isEmpty {
                        colorDistributionSection
                        Divider()
                    }
                    
                    // Book distribution
                    if !highlightsByBook.isEmpty {
                        bookDistributionSection
                        Divider()
                    }
                    
                    // Most highlighted verses
                    if !mostHighlightedVerses.isEmpty {
                        mostHighlightedSection
                        Divider()
                    }
                    
                    // Recent highlights
                    if !recentHighlights.isEmpty {
                        recentHighlightsSection
                    }
                }
                .padding()
            }
            .navigationTitle("Highlight Insights")
            .background(Color(.systemGroupedBackground))
        }
    }
    
    private var overviewSection: some View {
        VStack(spacing: 16) {
            Text("Overview")
                .font(.title2.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                StatCard(
                    title: "Total Highlights",
                    value: "\(totalHighlights)",
                    icon: "highlighter",
                    color: .yellow
                )
                
                StatCard(
                    title: "Books",
                    value: "\(highlightsByBook.count)",
                    icon: "book.closed.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "Colors Used",
                    value: "\(highlightsByColor.count)",
                    icon: "paintpalette.fill",
                    color: .purple
                )
            }
        }
    }
    
    private var colorDistributionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("By Color")
                .font(.title3.bold())
            
            if #available(iOS 16.0, *) {
                Chart(highlightsByColor) { item in
                    SectorMark(
                        angle: .value("Count", item.count),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                    .annotation(position: .overlay) {
                        VStack(spacing: 2) {
                            Text("\(item.count)")
                                .font(.caption.bold())
                            Text(item.colorName)
                                .font(.caption2)
                        }
                        .foregroundColor(.white)
                    }
                }
                .frame(height: 250)
            } else {
                // Fallback for iOS 15
                VStack(spacing: 12) {
                    ForEach(highlightsByColor, id: \.colorName) { item in
                        HStack {
                            Circle()
                                .fill(item.color)
                                .frame(width: 20, height: 20)
                            
                            Text(item.colorName)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(item.count)")
                                .font(.subheadline.bold())
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var bookDistributionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("By Book")
                .font(.title3.bold())
            
            if #available(iOS 16.0, *) {
                Chart(highlightsByBook) { item in
                    BarMark(
                        x: .value("Count", item.count),
                        y: .value("Book", item.bookName)
                    )
                    .foregroundStyle(Color.accentColor.gradient)
                    .annotation(position: .trailing) {
                        Text("\(item.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: CGFloat(highlightsByBook.count * 35))
                .chartXAxis(.hidden)
            } else {
                VStack(spacing: 8) {
                    ForEach(highlightsByBook.prefix(5), id: \.bookName) { item in
                        HStack {
                            Text(item.bookName)
                                .font(.caption)
                                .frame(width: 100, alignment: .leading)
                            
                            GeometryReader { geometry in
                                HStack(spacing: 0) {
                                    Rectangle()
                                        .fill(Color.accentColor)
                                        .frame(width: geometry.size.width * (Double(item.count) / Double(highlightsByBook.first?.count ?? 1)))
                                    
                                    Spacer(minLength: 0)
                                }
                            }
                            .frame(height: 20)
                            
                            Text("\(item.count)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
                .padding()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var mostHighlightedSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Most Highlighted Verses")
                .font(.title3.bold())
            
            VStack(spacing: 12) {
                ForEach(Array(mostHighlightedVerses.enumerated()), id: \.offset) { index, item in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("#\(index + 1)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(.secondary)
                                .frame(width: 30, alignment: .leading)
                            
                            Text(item.0.reference)
                                .font(.subheadline.bold())
                            
                            Spacer()
                            
                            Text("\(item.1) highlight\(item.1 == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text(item.0.text)
                            .font(.caption)
                            .lineLimit(2)
                            .padding(.leading, 30)
                    }
                    .padding(.vertical, 8)
                    
                    if index < mostHighlightedVerses.count - 1 {
                        Divider()
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6).opacity(0.5))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private var recentHighlightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Highlights")
                .font(.title3.bold())
            
            VStack(spacing: 12) {
                ForEach(recentHighlights) { highlight in
                    HStack(alignment: .top, spacing: 12) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(highlight.highlightColor)
                            .frame(width: 4)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(highlight.verse?.reference ?? "Unknown")
                                .font(.caption.bold())
                            
                            Text(highlight.text)
                                .font(.caption)
                                .lineLimit(2)
                            
                            Text(highlight.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func matchColorName(hex: String) -> String {
        for color in HighlightColor.allCases {
            if color.color.toHex() == hex {
                return color.rawValue
            }
        }
        return "Other"
    }
}

// MARK: - Supporting Types
struct ColorCount: Identifiable {
    let id = UUID()
    let color: Color
    let colorName: String
    let count: Int
}

struct BookCount: Identifiable {
    let id = UUID()
    let bookName: String
    let count: Int
}

// MARK: - Stat Card Component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title.bold())
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: Highlight.self,
        Verse.self,
        Chapter.self,
        Book.self,
        configurations: config
    )
    
    let context = container.mainContext
    let book = Book(name: "John", order: 43, testament: "NT")
    let chapter = Chapter(number: 3, book: book)
    let verse = Verse(number: 16, text: "For God so loved the world, that he gave his only begotten Son...", chapter: chapter)
    
    let highlight1 = Highlight(verseId: verse.id, startIndex: 0, endIndex: 10, color: .yellow, text: "For God so", verse: verse)
    let highlight2 = Highlight(verseId: verse.id, startIndex: 20, endIndex: 30, color: .green, text: "loved the ", verse: verse)
    
    context.insert(book)
    context.insert(chapter)
    context.insert(verse)
    context.insert(highlight1)
    context.insert(highlight2)
    
    return HighlightStatsView()
        .modelContainer(container)
}