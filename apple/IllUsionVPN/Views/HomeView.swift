import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var viewModel: AppViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    header

                    ConnectButton(state: viewModel.state) {
                        Task { await viewModel.toggleConnection() }
                    }
                    .padding(.top, 8)

                    statusPill

                    if viewModel.state.isConnected {
                        trafficCard
                    }

                    selectedServerCard

                    quickToggles
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
            .background(Theme.backgroundGradient.ignoresSafeArea())
        }
        .task(id: viewModel.state.isConnected) {
            guard viewModel.state.isConnected else { return }
            while !Task.isCancelled && viewModel.state.isConnected {
                await viewModel.tunnel.refreshStats()
                try? await Task.sleep(nanoseconds: 2_000_000_000)
            }
        }
    }

    private var trafficCard: some View {
        HStack(spacing: 0) {
            trafficColumn(icon: "arrow.down", title: "Загрузка",
                          value: viewModel.tunnel.stats.rxFormatted, tint: Theme.success)
            Divider().frame(height: 36).overlay(Theme.cardStroke)
            trafficColumn(icon: "arrow.up", title: "Отдача",
                          value: viewModel.tunnel.stats.txFormatted, tint: Theme.accent)
        }
        .glassCard()
    }

    private func trafficColumn(icon: String, title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 6) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
            Text(value)
                .font(.title3.monospacedDigit().weight(.semibold))
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("IllUsion")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Theme.accentGradient)
                Text("Приватность без компромиссов")
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
            Image(systemName: "bolt.shield.fill")
                .font(.title2)
                .foregroundStyle(Theme.accent)
        }
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            Circle().fill(viewModel.state.tint).frame(width: 10, height: 10)
            Text(viewModel.state.title)
                .font(.headline)
                .foregroundStyle(.white)
            if case let .connected(since) = viewModel.state {
                Text("·").foregroundStyle(.white.opacity(0.4))
                TimelineView(.periodic(from: .now, by: 1)) { _ in
                    Text(durationString(since: since))
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Capsule().fill(Theme.card))
        .overlay(Capsule().stroke(Theme.cardStroke, lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Статус подключения")
        .accessibilityValue(viewModel.state.title)
    }

    private var selectedServerCard: some View {
        NavigationLink {
            ServerListView()
        } label: {
            HStack(spacing: 14) {
                Text(viewModel.selectedServer?.flag ?? "🌐")
                    .font(.system(size: 34))
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.selectedServer?.city ?? "Выберите сервер")
                        .font(.headline).foregroundStyle(.white)
                    Text(viewModel.selectedServer?.country ?? "—")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                if let ms = viewModel.selectedServer?.latencyMs {
                    Text("\(ms) ms")
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Theme.success)
                }
                Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.4))
            }
            .glassCard()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Выбранный сервер")
        .accessibilityValue(viewModel.selectedServer.map { "\($0.city), \($0.country)" } ?? "Не выбран")
        .accessibilityHint("Дважды коснитесь, чтобы выбрать другой сервер")
    }

    private var quickToggles: some View {
        HStack(spacing: 12) {
            QuickToggle(
                title: "Kill Switch",
                icon: "hand.raised.fill",
                isOn: viewModel.settings.killSwitch
            ) {
                viewModel.updateSettings { $0.killSwitch.toggle() }
            }
            QuickToggle(
                title: "Multi-hop",
                icon: "arrow.triangle.swap",
                isOn: viewModel.settings.multihopEnabled
            ) {
                viewModel.updateSettings { $0.multihopEnabled.toggle() }
            }
            QuickToggle(
                title: "Обфускация",
                icon: "theatermasks.fill",
                isOn: viewModel.settings.obfuscationEnabled
            ) {
                viewModel.updateSettings { $0.obfuscationEnabled.toggle() }
            }
        }
    }

    private func durationString(since: Date) -> String {
        let s = Int(Date().timeIntervalSince(since))
        return String(format: "%02d:%02d:%02d", s / 3600, (s % 3600) / 60, s % 60)
    }
}

private struct QuickToggle: View {
    let title: String
    let icon: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isOn ? Theme.accent : .white.opacity(0.5))
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isOn ? Theme.accent.opacity(0.12) : Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isOn ? Theme.accent.opacity(0.5) : Theme.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "Включено" : "Выключено")
        .accessibilityAddTraits(isOn ? [.isButton, .isSelected] : .isButton)
    }
}
