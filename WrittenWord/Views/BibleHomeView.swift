import SwiftUI

struct BibleHomeView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            Text("Bible")
                .font(.largeTitle)
                .fontWeight(.bold)
            Text("Choose a book and chapter from the sidebar to begin reading.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Bible")
        .background(Color(.systemBackground))
    }
}

#Preview {
    NavigationStack {
        BibleHomeView()
    }
}
