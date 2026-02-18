import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: BeerTrackerStore
    @State private var showResetConfirmation = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Tracking") {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        Text("Reset Start Date and Clear Entries")
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Reset Tracking?", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    store.resetTracking()
                }
            } message: {
                Text("This will set Start Date to today and remove all entries.")
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(BeerTrackerStore())
}
