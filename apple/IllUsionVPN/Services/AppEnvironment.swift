import Foundation

/// Конфигурация окружения приложения.
///
/// В симуляторе NetworkExtension недоступен, поэтому включается «демо-режим»:
/// UI работает полностью, подключение имитируется, серверы берутся из бандла.
/// На реальном устройстве используется backend и настоящий WireGuard-туннель.
enum AppEnvironment {
    static var isSimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    /// Демо-режим: без реального туннеля и без обязательного backend.
    static var isDemoMode: Bool {
        // Принудительно можно включить через переменную окружения.
        if ProcessInfo.processInfo.environment["ILLUSION_DEMO"] == "1" { return true }
        return isSimulator
    }

    /// Загрузка офлайн-списка серверов из ресурсов бандла.
    static func bundledServers() -> [Server] {
        guard
            let url = Bundle.main.url(forResource: "bundledServers", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let response = try? JSONDecoder().decode(ServerListResponse.self, from: data)
        else {
            return []
        }
        return response.servers
    }
}
