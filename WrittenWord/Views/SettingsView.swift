//
//  SettingsView.swift
//  WrittenWord
//
//  Created by Andrew Bales on 1/21/26.
//
import SwiftUI

struct SettingsView: View {
    @AppStorage("notePosition") private var notePosition: NotePosition = .right
    
    var body: some View {
        Form {
            Section("Notes") {
                Picker("Note Position", selection: $notePosition) {
                    ForEach(NotePosition.allCases, id: \.self) { position in
                        Text(position.displayName).tag(position)
                    }
                }
                .pickerStyle(.segmented)
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
