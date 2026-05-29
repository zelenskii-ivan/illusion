import SwiftUI

struct ServerListView: View {
    @EnvironmentObject private var viewModel: AppViewModel
    @EnvironmentObject private var store: StoreService
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var showPaywall = false

    private func select(_ server: Server) {
        if server.tier == .premium && !store.isPremium {
            showPaywall = true
            return
        }
        viewModel.selectedServer = server
        dismiss()
    }

    private var filtered: [Server] {
        guard !query.isEmpty else { return viewModel.servers }
        return viewModel.servers.filter {
            $0.country.localizedCaseInsensitiveContains(query) ||
            $0.city.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                ScrollView {
                    LazyVStack(spacing: 12) {
                        fastestButton
                        ForEach(filtered) { server in
                            ServerRow(
                                server: server,
                                isSelected: server.id == viewModel.selectedServer?.id,
                                locked: server.tier == .premium && !store.isPremium
                            ) {
                                select(server)
                            }
                        }
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
                .refreshable { await viewModel.refreshServers() }
            }
            .navigationTitle("Серверы")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $query, prompt: "Страна или город")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isLoading { ProgressView().tint(.white) }
                }
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
        }
    }

    private var fastestButton: some View {
        Button {
            viewModel.selectFastestServer()
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "bolt.fill").foregroundStyle(Theme.warning)
                Text("Самый быстрый сервер")
                    .font(.headline).foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(.white.opacity(0.4))
            }
            .glassCard()
        }
        .buttonStyle(.plain)
    }
}

private struct ServerRow: View {
    let server: Server
    let isSelected: Bool
    var locked: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Text(server.flag ?? "🌐").font(.system(size: 30))
                    .opacity(locked ? 0.5 : 1)
                VStack(alignment: .leading, spacing: 3) {
                    Text(server.city).font(.headline).foregroundStyle(.white)
                    HStack(spacing: 6) {
                        Text(server.country)
                        if server.tier == .premium {
                            Text("PRO")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Theme.accentGradient)
                                .clipShape(Capsule())
                        }
                    }
                    .font(.subheadline).foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    if let ms = server.latencyMs {
                        Text("\(ms) ms")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(latencyColor(ms))
                    }
                    LoadBar(load: server.load)
                }
                if locked {
                    Image(systemName: "lock.fill").foregroundStyle(Theme.warning)
                } else if isSelected {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.success)
                }
            }
            .glassCard()
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .stroke(isSelected ? Theme.accent : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(server.city), \(server.country)")
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(locked ? "Премиум-сервер. Дважды коснитесь, чтобы оформить подписку" : "")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var accessibilityValue: String {
        var parts: [String] = []
        if let ms = server.latencyMs { parts.append("задержка \(ms) миллисекунд") }
        parts.append("нагрузка \(server.loadLabel)")
        if locked { parts.append("заблокировано") }
        return parts.joined(separator: ", ")
    }

    private func latencyColor(_ ms: Int) -> Color {
        switch ms {
        case ..<60: return Theme.success
        case ..<150: return Theme.warning
        default: return Theme.danger
        }
    }
}

private struct LoadBar: View {
    let load: Int
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5) { i in
                Capsule()
                    .fill(i < load / 20 ? barColor : Color.white.opacity(0.15))
                    .frame(width: 4, height: 10)
            }
        }
    }
    private var barColor: Color {
        switch load {
        case ..<34: return Theme.success
        case ..<67: return Theme.warning
        default: return Theme.danger
        }
    }
}
