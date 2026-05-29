import Foundation
import SwiftUI

@MainActor
final class AppViewModel: ObservableObject {
    @Published var servers: [Server] = []
    @Published var selectedServer: Server?
    @Published var exitServer: Server?            // для multi-hop
    @Published var settings: AppSettings = SettingsStore.load()
    @Published var isLoading = false
    @Published var errorMessage: String?

    let tunnel = TunnelManager()

    var state: ConnectionState { tunnel.state }

    // MARK: - Загрузка данных

    func bootstrap() async {
        if AppEnvironment.isDemoMode {
            loadBundledServers()
            return
        }
        await login()
        await refreshServers()
    }

    func login() async {
        do {
            // Демо-вход. В проде — экран авторизации.
            let resp = try await APIClient.shared.login(email: "demo@illusion.vpn", password: "demo")
            await APIClient.shared.setToken(resp.token)
        } catch {
            errorMessage = "Не удалось войти: \(error.localizedDescription)"
        }
    }

    func refreshServers() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let fetched = try await APIClient.shared.fetchServers()
            let ranked = await LatencyProbe.rank(fetched)
            servers = ranked
            if selectedServer == nil { selectedServer = ranked.first }
        } catch {
            // Backend недоступен — используем офлайн-список из бандла.
            loadBundledServers()
        }
    }

    /// Загружает встроенный список серверов (офлайн / демо-режим).
    private func loadBundledServers() {
        var bundled = AppEnvironment.bundledServers()
        if AppEnvironment.isDemoMode {
            // Синтетические задержки, чтобы список выглядел реалистично.
            for index in bundled.indices {
                bundled[index].latencyMs = Int.random(in: 12...180)
            }
            bundled.sort { ($0.latencyMs ?? .max) < ($1.latencyMs ?? .max) }
        }
        servers = bundled
        if selectedServer == nil { selectedServer = bundled.first }
    }

    /// Умный выбор: сервер с наименьшей задержкой.
    func selectFastestServer() {
        selectedServer = servers.min { ($0.latencyMs ?? .max) < ($1.latencyMs ?? .max) }
    }

    // MARK: - Подключение

    func toggleConnection() async {
        if tunnel.state.isConnected || tunnel.state == .connecting {
            await tunnel.disconnect()
        } else {
            await connect()
        }
    }

    func connect() async {
        guard let server = selectedServer else {
            errorMessage = "Сначала выберите сервер"
            return
        }

        // Демо-режим (симулятор): имитируем подключение без NetworkExtension.
        if AppEnvironment.isDemoMode {
            await tunnel.connectDemo()
            return
        }

        let keys = WireGuardKeys.generate()
        do {
            let exitId = settings.multihopEnabled ? exitServer?.id : nil
            let session = try await APIClient.shared.createSession(
                serverId: server.id,
                exitServerId: exitId,
                publicKey: keys.publicKeyBase64
            )
            await tunnel.connect(
                session: session,
                privateKey: keys.privateKeyBase64,
                server: server,
                settings: settings
            )
        } catch {
            errorMessage = "Ошибка подключения: \(error.localizedDescription)"
        }
    }

    // MARK: - Настройки

    func updateSettings(_ transform: (inout AppSettings) -> Void) {
        transform(&settings)
        SettingsStore.save(settings)
    }
}
