import SwiftUI
import SwiftData

@main
struct VitaCoachApp: App {
    @State private var container = AppContainer()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(container)
                .tint(Theme.accent)
                .preferredColorScheme(.dark)
                .task { container.seedInitialDataIfNeeded() }
        }
        .modelContainer(container.modelContainer)
    }
}
