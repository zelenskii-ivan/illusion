import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var auth: AuthService

    @State private var email = ""
    @State private var password = ""
    @State private var error: String?

    private var canSubmit: Bool {
        email.contains("@") && password.count >= 4 && !auth.isWorking
    }

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                VStack(spacing: 10) {
                    Image(systemName: "bolt.shield.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Theme.accentGradient)
                    Text("IllUsion")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.white)
                    Text("Войдите, чтобы продолжить")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                }

                VStack(spacing: 14) {
                    field("Email", text: $email, icon: "envelope.fill")
                    secureField("Пароль", text: $password, icon: "lock.fill")
                }
                .glassCard()

                if let error {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Theme.danger)
                        .multilineTextAlignment(.center)
                }

                Button(action: submit) {
                    HStack {
                        if auth.isWorking { ProgressView().tint(.white) }
                        Text("Войти").font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canSubmit ? Theme.accentGradient : LinearGradient(colors: [.gray.opacity(0.3)], startPoint: .top, endPoint: .bottom))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .disabled(!canSubmit)

                Spacer()

                Text("Продолжая, вы принимаете Условия и Политику конфиденциальности.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
    }

    private func submit() {
        error = nil
        Task {
            do {
                try await auth.signIn(email: email, password: password)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func field(_ title: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).frame(width: 24).foregroundStyle(Theme.accent)
            TextField(title, text: text)
                .emailKeyboard()
                .noAutocapitalization()
                .autocorrectionDisabled()
                .foregroundStyle(.white)
        }
        .padding(.vertical, 6)
    }

    private func secureField(_ title: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).frame(width: 24).foregroundStyle(Theme.accent)
            SecureField(title, text: text).foregroundStyle(.white)
        }
        .padding(.vertical, 6)
    }
}
