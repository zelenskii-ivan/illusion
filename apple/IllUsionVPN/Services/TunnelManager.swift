import Foundation
import NetworkExtension

/// Управляет системным VPN-профилем (NETunnelProviderManager) и передаёт
/// WireGuard-конфиг расширению PacketTunnelProvider.
@MainActor
final class TunnelManager: ObservableObject {
    @Published private(set) var state: ConnectionState = .disconnected
    @Published private(set) var stats: TunnelStats = .init()

    private var manager: NETunnelProviderManager?
    private var statusObserver: NSObjectProtocol?
    private var isDemo = false
    private var demoTask: Task<Void, Never>?

    private let tunnelBundleId = "com.illusion.vpn.PacketTunnel"

    init() {
        if AppEnvironment.isDemoMode { return }
        Task { await loadManager() }
    }

    deinit {
        if let statusObserver { NotificationCenter.default.removeObserver(statusObserver) }
    }

    // MARK: - Загрузка / создание профиля

    func loadManager() async {
        do {
            let managers = try await NETunnelProviderManager.loadAllFromPreferences()
            let manager = managers.first ?? NETunnelProviderManager()
            self.manager = manager
            observeStatus(of: manager.connection)
            updateState(from: manager.connection.status)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: - Публичный API

    func connect(session: Session, privateKey: String, server: Server, settings: AppSettings) async {
        state = .connecting
        stats = .init()
        do {
            let manager = try await ensureManager(server: server, settings: settings)
            let config = session.wgQuickConfig(privateKey: privateKey)

            let proto = (manager.protocolConfiguration as? NETunnelProviderProtocol)
                ?? NETunnelProviderProtocol()
            proto.providerBundleIdentifier = tunnelBundleId
            proto.serverAddress = server.host
            // Конфиг WireGuard передаётся расширению. В проде — через защищённое
            // хранилище / keychain, здесь — через providerConfiguration.
            proto.providerConfiguration = ["wgQuickConfig": config]

            // Kill Switch: блокировать весь трафик вне туннеля.
            proto.includeAllNetworks = settings.killSwitch
            proto.excludeLocalNetworks = true

            manager.protocolConfiguration = proto
            manager.localizedDescription = "IllUsion · \(server.city)"
            manager.isEnabled = true
            manager.onDemandRules = buildOnDemandRules(settings: settings)
            manager.isOnDemandEnabled = settings.alwaysOn || settings.autoConnectUntrustedWiFi

            try await manager.saveToPreferences()
            try await manager.loadFromPreferences()

            try manager.connection.startVPNTunnel()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Запрашивает у расширения текущие счётчики трафика.
    func refreshStats() async {
        if isDemo {
            stats.rxBytes += UInt64.random(in: 4_000...90_000)
            stats.txBytes += UInt64.random(in: 2_000...40_000)
            return
        }
        guard let session = manager?.connection as? NETunnelProviderSession,
              let message = "getStats".data(using: .utf8) else { return }
        do {
            try session.sendProviderMessage(message) { [weak self] data in
                guard let data, let config = String(data: data, encoding: .utf8) else { return }
                Task { @MainActor in self?.stats = TunnelStats.parse(config) }
            }
        } catch {
            Log.tunnel.error("Не удалось получить статистику: \(error.localizedDescription, privacy: .public)")
        }
    }

    func disconnect() async {
        if isDemo {
            await disconnectDemo()
            return
        }
        state = .disconnecting
        // Отключаем on-demand, иначе туннель поднимется снова.
        if let manager {
            manager.isOnDemandEnabled = false
            try? await manager.saveToPreferences()
        }
        manager?.connection.stopVPNTunnel()
    }

    // MARK: - Демо-режим (симулятор, без NetworkExtension)

    /// Имитирует полный цикл подключения с задержкой.
    func connectDemo() async {
        isDemo = true
        state = .connecting
        stats = .init()
        demoTask?.cancel()
        demoTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { self?.state = .connected(since: Date()) }
        }
    }

    func disconnectDemo() async {
        demoTask?.cancel()
        state = .disconnecting
        try? await Task.sleep(nanoseconds: 500_000_000)
        state = .disconnected
    }

    // MARK: - Внутреннее

    private func ensureManager(server: Server, settings: AppSettings) async throws -> NETunnelProviderManager {
        if let manager { return manager }
        let manager = NETunnelProviderManager()
        self.manager = manager
        observeStatus(of: manager.connection)
        return manager
    }

    /// Правила автоподключения: Always-On и/или подключение на недоверенных Wi‑Fi.
    private func buildOnDemandRules(settings: AppSettings) -> [NEOnDemandRule] {
        guard settings.alwaysOn || settings.autoConnectUntrustedWiFi else { return [] }
        let connectRule = NEOnDemandRuleConnect()
        connectRule.interfaceTypeMatch = .any
        return [connectRule]
    }

    private func observeStatus(of connection: NEVPNConnection) {
        if let statusObserver { NotificationCenter.default.removeObserver(statusObserver) }
        statusObserver = NotificationCenter.default.addObserver(
            forName: .NEVPNStatusDidChange,
            object: connection,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.updateState(from: connection.status) }
        }
    }

    private func updateState(from status: NEVPNStatus) {
        switch status {
        case .invalid, .disconnected:
            state = .disconnected
        case .connecting, .reasserting:
            state = .connecting
        case .connected:
            state = .connected(since: manager?.connection.connectedDate ?? Date())
        case .disconnecting:
            state = .disconnecting
        @unknown default:
            state = .disconnected
        }
    }
}
