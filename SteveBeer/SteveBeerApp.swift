import SwiftUI

@main
struct SteveBeerApp: App {
    @StateObject private var store = BeerTrackerStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
