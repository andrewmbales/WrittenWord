//
//  SettingsView.swift
//  WrittenWord
//
//  Updated to use shared UITypes
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
                    Slider(value: $lineSpacing, in: 2...36, step: 2)
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

#Preview {
    NavigationStack {
        SettingsView()
    }
}