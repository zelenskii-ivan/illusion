import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0

    private struct Page: Identifiable {
        let id = UUID()
        let icon: String
        let title: LocalizedStringKey
        let subtitle: LocalizedStringKey
    }

    private let pages: [Page] = [
        .init(icon: "bolt.shield.fill",
              title: "Защита одним касанием",
              subtitle: "Современный протокол WireGuard — быстрое и надёжное шифрование вашего трафика."),
        .init(icon: "globe",
              title: "Серверы по всему миру",
              subtitle: "Выбирайте локацию вручную или доверьтесь авто-выбору самого быстрого сервера."),
        .init(icon: "lock.shield.fill",
              title: "Приватность без компромиссов",
              subtitle: "Kill Switch, Multi-hop и обфускация. Мы не ведём логи вашей активности.")
    ]

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()

            VStack {
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, item in
                        VStack(spacing: 24) {
                            Spacer()
                            Image(systemName: item.icon)
                                .font(.system(size: 96))
                                .foregroundStyle(Theme.accentGradient)
                                .shadow(color: Theme.accent.opacity(0.5), radius: 30)
                            Text(item.title)
                                .font(.title.bold())
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                            Text(item.subtitle)
                                .font(.body)
                                .foregroundStyle(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                            Spacer()
                        }
                        .tag(index)
                    }
                }
                .pagedTabStyle()

                Button(action: next) {
                    Text(page == pages.count - 1 ? "Начать" : "Далее")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Theme.accentGradient)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
    }

    private func next() {
        if page < pages.count - 1 {
            withAnimation { page += 1 }
        } else {
            onFinish()
        }
    }
}
