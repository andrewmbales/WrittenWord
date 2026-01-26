//
//  SettingsView.swift
//  WrittenWord
//
//  Enhanced with Phase 1 improvements
//
import SwiftUI

struct SettingsView: View {
    @AppStorage("notePosition") private var notePosition: NotePosition = .right
    @AppStorage("fontSize") private var fontSize: Double = 16.0
    @AppStorage("lineSpacing") private var lineSpacing: Double = 6.0
    @AppStorage("colorTheme") private var colorTheme: ColorTheme = .system
    @AppStorage("fontFamily") private var fontFamily: FontFamily = .system
    
    var body: some View {
        Form {
            Section("Reading") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Font Size")
                        Spacer()
                        Text("\(Int(fontSize))")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $fontSize, in: 12...24, step: 1)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Line Spacing")
                        Spacer()
                        Text("\(Int(lineSpacing))")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $lineSpacing, in: 2...12, step: 2)
                }
                
                Picker("Font Family", selection: $fontFamily) {
                    ForEach(FontFamily.allCases, id: \.self) { family in
                        Text(family.displayName).tag(family)
                    }
                }
            }
            
            Section("Appearance") {
                Picker("Theme", selection: $colorTheme) {
                    ForEach(ColorTheme.allCases, id: \.self) { theme in
                        Label(theme.displayName, systemImage: theme.icon)
                            .tag(theme)
                    }
                }
                
                // Preview
                VStack(alignment: .leading, spacing: 4) {
                    Text("Preview")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("In the beginning God created the heaven and the earth.")
                        .font(.system(size: fontSize))
                        .lineSpacing(lineSpacing)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(colorTheme.backgroundColor)
                        .foregroundColor(colorTheme.textColor)
                        .cornerRadius(8)
                }
            }
            
            Section("Notes") {
                Picker("Note Position", selection: $notePosition) {
                    ForEach(NotePosition.allCases, id: \.self) { position in
                        Text(position.displayName).tag(position)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
                
                Link(destination: URL(string: "https://github.com")!) {
                    HStack {
                        Text("GitHub")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Settings")
    }
}

enum ColorTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"
    case sepia = "Sepia"
    case sand = "Sand"
    
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .system: return "sparkles"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .sepia: return "book.fill"
        case .sand: return "beach.umbrella.fill"
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .system: return Color(.systemBackground)
        case .light: return Color.white
        case .dark: return Color.black
        case .sepia: return Color(red: 0.95, green: 0.91, blue: 0.82)
        case .sand: return Color(red: 0.98, green: 0.95, blue: 0.88)
        }
    }
    
    var textColor: Color {
        switch self {
        case .system: return Color(.label)
        case .light: return Color.black
        case .dark: return Color.white
        case .sepia: return Color(red: 0.2, green: 0.15, blue: 0.1)
        case .sand: return Color(red: 0.3, green: 0.25, blue: 0.2)
        }
    }
}

enum FontFamily: String, CaseIterable {
    case system = "System"
    case serif = "Serif"
    case rounded = "Rounded"
    case monospaced = "Monospaced"
    
    var displayName: String { rawValue }
    
    func font(size: CGFloat) -> Font {
        switch self {
        case .system: return .system(size: size)
        case .serif: return .custom("Georgia", size: size)
        case .rounded: return .system(size: size, design: .rounded)
        case .monospaced: return .system(size: size, design: .monospaced)
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}