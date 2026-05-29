import ActivityKit
import Foundation

/// Атрибуты Live Activity статуса VPN. Файл общий для приложения и виджет-расширения.
struct VPNActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var statusText: String
        var isConnected: Bool
        /// Время установки соединения (для таймера на Lock Screen).
        var connectedSince: Date?
    }

    /// Статичные данные сессии.
    var serverCity: String
    var serverCountry: String
    var serverFlag: String
}
