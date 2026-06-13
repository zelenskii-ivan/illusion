import SwiftUI
import SwiftData

@main
struct VitaCoachApp: App {
    @State private var container = AppContainer()
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environment(container)
                    .tint(Theme.accent)
                    .task { container.seedInitialDataIfNeeded() }

                if showSplash {
                    LaunchView { withAnimation(.easeOut(duration: 0.45)) { showSplash = false } }
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .preferredColorScheme(.dark)
        }
        .modelContainer(container.modelContainer)
    }
}
