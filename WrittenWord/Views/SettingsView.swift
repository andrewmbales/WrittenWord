//
//  SettingsView.swift
//  WrittenWord
//
//  ENHANCED: Added adjustable left/right margins for note-taking
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("fontSize") private var fontSize: Double = 16.0
    @AppStorage("lineSpacing") private var lineSpacing: Double = 6.0
    @AppStorage("fontFamily") private var fontFamily: FontFamily = .system
    @AppStorage("colorTheme") private var colorTheme: ColorTheme = .system
    @AppStorage("notePosition") private var notePosition: NotePosition = .right
    
    // NEW: Adjustable margins
    @AppStorage("leftMargin") private var leftMargin: Double = 40.0
    @AppStorage("rightMargin") private var rightMargin: Double = 40.0
    
    // Highlight palette style
    @AppStorage("paletteStyle") private var paletteStyle: PaletteStyle = .horizontal

    // Debug options
    @AppStorage("showVerseBorders") private var showVerseBorders: Bool = false
    
    var body: some View {
        Form {
            // Text Display Section
            Section("Text Display") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Font Size")
                        Spacer()
                        Text("\(Int(fontSize))")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $fontSize, in: 12...28, step: 1)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Verse Spacing")
                        Spacer()
                        Text("\(Int(lineSpacing)) pt")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $lineSpacing, in: 0...36, step: 2)
                }
                
                Picker("Font Family", selection: $fontFamily) {
                    ForEach(FontFamily.allCases, id: \.self) { family in
                        Text(family.displayName).tag(family)
                    }
                }
                .pickerStyle(.segmented)
                
                Picker("Color Theme", selection: $colorTheme) {
                    ForEach(ColorTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // NEW: Margins Section
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Left Margin")
                        Spacer()
                        Text("\(Int(leftMargin)) pt")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $leftMargin, in: 30...250, step: 10)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Right Margin")
                        Spacer()
                        Text("\(Int(rightMargin)) pt")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $rightMargin, in: 0...250, step: 10)
                }
                
                Button("Reset to Defaults") {
                    leftMargin = 40.0
                    rightMargin = 40.0
                }
                .frame(maxWidth: .infinity, alignment: .center)
                
            } header: {
                Text("Margins")
            } footer: {
                Text("Adjust margins to create space for handwritten notes and annotations. Larger margins are helpful for detailed note-taking with Apple Pencil.")
            }
            
            // Preview Section
            Section("Preview") {
                GroupBox {
                    HStack(spacing: 0) {
                        // Left margin indicator
                        Rectangle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: leftMargin * 0.5) // Scaled for preview

                        VStack(alignment: .leading, spacing: lineSpacing) {
                            Text("1 In the beginning God created the heaven and the earth.")
                                .font(.system(size: fontSize))
                            Text("2 And the earth was without form, and void.")
                                .font(.system(size: fontSize))
                        }
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(colorTheme.backgroundColor)
                        .foregroundColor(colorTheme.textColor)

                        // Right margin indicator
                        Rectangle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: rightMargin * 0.5) // Scaled for preview
                    }
                    .cornerRadius(8)
                }
                
                Text("Blue areas show margin space for annotations")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Highlighting Section
            Section {
                Picker("Palette Style", selection: $paletteStyle) {
                    ForEach(PaletteStyle.allCases, id: \.self) { style in
                        Label(style.rawValue, systemImage: style.icon).tag(style)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(paletteStyle.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    // Live preview of selected style
                    Group {
                        switch paletteStyle {
                        case .horizontal:
                            HorizontalHighlightPalette(
                                selectedColor: .constant(.yellow),
                                onHighlight: { _ in },
                                onRemove: { },
                                onDismiss: { }
                            )
                        case .popover:
                            CompactPopoverPalette(
                                selectedColor: .constant(.blue),
                                onHighlight: { _ in },
                                onRemove: { },
                                onDismiss: { }
                            )
                        }
                    }
                    .allowsHitTesting(false)
                    .scaleEffect(0.85)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                }
            } header: {
                Text("Highlighting")
            } footer: {
                Text("Choose how the highlight color picker appears when you select text.")
            }

            // Debug Options Section
            Section("Debug Options") {
                Toggle("Show Verse Borders", isOn: $showVerseBorders)
                
                if showVerseBorders {
                    Text("Red borders will appear around each verse to help visualize layout and spacing.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .scrollContentBackground(.hidden)
        .background(colorTheme.backgroundColor)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
