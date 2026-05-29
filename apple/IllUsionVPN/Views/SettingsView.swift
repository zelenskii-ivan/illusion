import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var store: StoreService
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        premiumBanner

                        section("Безопасность") {
                            toggle("Kill Switch", "Блокировать трафик при разрыве туннеля",
                                   icon: "hand.raised.fill",
                                   value: viewModel.settings.killSwitch) { $0.killSwitch = $1 }
                            toggle("Always-On", "Держать VPN всегда включённым",
                                   icon: "infinity",
                                   value: viewModel.settings.alwaysOn) { $0.alwaysOn = $1 }
                            toggle("Авто на чужом Wi-Fi", "Подключаться на недоверенных сетях",
                                   icon: "wifi.exclamationmark",
                                   value: viewModel.settings.autoConnectUntrustedWiFi) { $0.autoConnectUntrustedWiFi = $1 }
                        }

                        section("Приватность") {
                            toggle("Multi-hop (Double VPN)", "Маршрут через два сервера",
                                   icon: "arrow.triangle.swap",
                                   value: viewModel.settings.multihopEnabled) { $0.multihopEnabled = $1 }
                            toggle("Обфускация (анти-DPI)", "Маскировать VPN-трафик",
                                   icon: "theatermasks.fill",
                                   value: viewModel.settings.obfuscationEnabled) { $0.obfuscationEnabled = $1 }
                            toggle("Блокировка рекламы и трекеров", "Фильтрация на уровне DNS",
                                   icon: "nosign",
                                   value: viewModel.settings.blockAdsAndTrackers) { $0.blockAdsAndTrackers = $1 }
                        }

                        section("Сеть") {
                            NavigationLink {
                                MultihopExitView()
                            } label: {
                                row("Выходной сервер (multi-hop)",
                                    subtitle: viewModel.exitServer?.city ?? "Не выбран",
                                    icon: "point.topleft.down.to.point.bottomright.curvepath")
                            }
                            .buttonStyle(.plain)
                            .disabled(!viewModel.settings.multihopEnabled)
                            .opacity(viewModel.settings.multihopEnabled ? 1 : 0.4)

                            dnsField
                        }

                        section("О приложении") {
                            row("Версия", subtitle: appVersion, icon: "info.circle")
                            row("Протокол", subtitle: "WireGuard", icon: "lock.shield")
                        }

                        Button(role: .destructive) {
                            Task { await auth.signOut() }
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Выйти из аккаунта")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .foregroundStyle(Theme.danger)
                            .background(Theme.danger.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Настройки")
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    @ViewBuilder
    private var premiumBanner: some View {
        Button { if !store.isPremium { showPaywall = true } } label: {
            HStack(spacing: 14) {
                Image(systemName: store.isPremium ? "crown.fill" : "crown")
                    .font(.title2)
                    .foregroundStyle(Theme.accentGradient)
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.isPremium ? "IllUsion Premium" : "Перейти на Premium")
                        .font(.headline).foregroundStyle(.white)
                    Text(store.isPremium ? "Подписка активна" : "Все локации, multi-hop, обфускация")
                        .font(.caption).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                if !store.isPremium {
                    Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.4))
                } else {
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(Theme.success)
                }
            }
            .glassCard()
        }
        .buttonStyle(.plain)
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    // MARK: - Конструкторы UI

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.leading, 4)
            VStack(spacing: 0) { content() }
                .glassCard()
        }
    }

    private func toggle(
        _ title: String, _ subtitle: String, icon: String,
        value: Bool, set: @escaping (inout AppSettings, Bool) -> Void
    ) -> some View {
        Toggle(isOn: Binding(
            get: { value },
            set: { newValue in viewModel.updateSettings { set(&$0, newValue) } }
        )) {
            label(title, subtitle: subtitle, icon: icon)
        }
        .tint(Theme.accent)
        .padding(.vertical, 8)
    }

    private func row(_ title: String, subtitle: String, icon: String) -> some View {
        HStack {
            label(title, subtitle: subtitle, icon: icon)
            Spacer()
            Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.3))
        }
        .padding(.vertical, 8)
    }

    private func label(_ title: String, subtitle: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .frame(width: 28)
                .foregroundStyle(Theme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body).foregroundStyle(.white)
                Text(subtitle).font(.caption).foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    private var dnsField: some View {
        HStack(spacing: 12) {
            Image(systemName: "network").frame(width: 28).foregroundStyle(Theme.accent)
            TextField("Кастомный DNS (необязательно)", text: Binding(
                get: { viewModel.settings.customDNS },
                set: { newValue in viewModel.updateSettings { $0.customDNS = newValue } }
            ))
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .foregroundStyle(.white)
        }
        .padding(.vertical, 8)
    }
}

/// Выбор выходного сервера для multi-hop.
private struct MultihopExitView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.servers.filter { $0.supportsMultihopExit }) { server in
                        Button {
                            viewModel.exitServer = server
                            dismiss()
                        } label: {
                            HStack(spacing: 14) {
                                Text(server.flag ?? "🌐").font(.system(size: 28))
                                Text("\(server.city), \(server.country)")
                                    .foregroundStyle(.white)
                                Spacer()
                                if viewModel.exitServer?.id == server.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(Theme.success)
                                }
                            }
                            .glassCard()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Выходной сервер")
        .navigationBarTitleDisplayMode(.inline)
    }
}
