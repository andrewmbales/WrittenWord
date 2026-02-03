import SwiftUI

struct ColorPickerSheet: View {
    @Binding var selectedColor: Color
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ColorPicker("Highlight Color", selection: $selectedColor, supportsOpacity: true)
                    .padding()
                Spacer()
            }
            .navigationTitle("Choose Color")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
