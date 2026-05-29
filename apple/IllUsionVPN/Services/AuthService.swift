import Foundation
import SwiftUI

/// Состояние аутентификации. Токен хранится в Keychain (через APIClient).
@MainActor
final class AuthService: ObservableObject {
    enum State: Equatable {
        case unknown
        case signedOut
        case signedIn(email: String)
    }

    @Published private(set) var state: State = .unknown
    @Published var isWorking = false

    var isSignedIn: Bool { if case .signedIn = state { return true }; return false }

    func restore() async {
        if AppEnvironment.isDemoMode {
            state = .signedIn(email: "demo@illusion.vpn")
            return
        }
        let authenticated = await APIClient.shared.isAuthenticated
        state = authenticated ? .signedIn(email: lastEmail ?? "—") : .signedOut
    }

    func signIn(email: String, password: String) async throws {
        isWorking = true
        defer { isWorking = false }
        let response = try await APIClient.shared.login(email: email, password: password)
        lastEmail = response.user.email
        Log.auth.info("Вход выполнен")
        state = .signedIn(email: response.user.email)
    }

    func signOut() async {
        await APIClient.shared.logout()
        lastEmail = nil
        state = .signedOut
    }

    // Email не является секретом; храним для отображения между сессиями.
    private var lastEmail: String? {
        get { UserDefaults.standard.string(forKey: "auth.lastEmail") }
        set { UserDefaults.standard.set(newValue, forKey: "auth.lastEmail") }
    }
}
