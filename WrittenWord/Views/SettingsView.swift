//
//  SettingsView.swift
//  WrittenWord
//
//  Settings with verse border debug toggle
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("fontSize") private var fontSize: Double = 16.0
    @AppStorage("lineSpacing") private var lineSpacing: Double = 6.0
    @AppStorage("fontFamily") private var fontFamily: FontFamily = .system
    @AppStorage("colorTheme") private var colorTheme: ColorTheme = .system
    @AppStorage("notePosition") private var notePosition: NotePosition = .right
    
    // NEW: Debug options
    @AppStorage("showVerseBorders") private var showVerseBorders: Bool = false
    
    var body: some View {
        Form {
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
                .pickerStyle(.segmented)
                
                Picker("Color Theme", selection: $colorTheme) {
                    ForEach(ColorTheme.allCases, id: \.self) { theme in
                        Text(theme.displayName).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
                
                // Preview
                GroupBox("Preview") {
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
            
            Section("Debug Options") {
                Toggle("Show Verse Borders", isOn: $showVerseBorders)
                
                if showVerseBorders {
                    Text("Red borders will appear around each verse to help visualize layout and spacing.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // In SettingsView.swift, add to "Debug Options" section:
                NavigationLink {
                    InterlinearDataVerificationView()
                } label: {
                    Label("Verify Interlinear Data", systemImage: "checkmark.circle")
                }
                
                NavigationLink {
                    InterlinearDataDebugView()
                } label: {
                    Label("Interlinear Debug", systemImage: "ladybug")
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
