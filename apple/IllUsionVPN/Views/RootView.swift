import SwiftUI

struct RootView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @State private var tab: Tab = .home

    enum Tab { case home, servers, settings }

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()

            TabView(selection: $tab) {
                HomeView()
                    .tag(Tab.home)
                    .tabItem { Label("Главная", systemImage: "shield.lefthalf.filled") }

                ServerListView()
                    .tag(Tab.servers)
                    .tabItem { Label("Серверы", systemImage: "globe") }

                SettingsView()
                    .tag(Tab.settings)
                    .tabItem { Label("Настройки", systemImage: "slider.horizontal.3") }
            }
            .tint(Theme.accent)
        }
        .alert(
            "Что-то пошло не так",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )
        ) {
            Button("Ок", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}
