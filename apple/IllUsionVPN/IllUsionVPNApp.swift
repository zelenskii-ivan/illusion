import SwiftUI

@main
struct IllUsionVPNApp: App {
    @StateObject private var viewModel = AppViewModel()
    @StateObject private var auth = AuthService()
    @StateObject private var store = StoreService()
    @AppStorage("onboarding.completed") private var onboardingCompleted = false

    var body: some Scene {
        WindowGroup {
            Group {
                if !onboardingCompleted {
                    OnboardingView { onboardingCompleted = true }
                } else {
                    switch auth.state {
                    case .unknown:
                        SplashView()
                    case .signedOut:
                        LoginView()
                    case .signedIn:
                        RootView()
                    }
                }
            }
            .environmentObject(viewModel)
            .environmentObject(auth)
            .environmentObject(store)
            .preferredColorScheme(.dark)
            .task {
                await auth.restore()
                await store.loadProducts()
                if auth.isSignedIn { await viewModel.bootstrap() }
            }
            .onChange(of: auth.isSignedIn) { signedIn in
                if signedIn { Task { await viewModel.bootstrap() } }
            }
        }
    }
}

/// Экран загрузки на время восстановления сессии.
private struct SplashView: View {
    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "bolt.shield.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.accentGradient)
                ProgressView().tint(.white)
            }
        }
    }
}
