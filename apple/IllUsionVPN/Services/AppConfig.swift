import Foundation

/// Конфигурация окружения. Значения берутся из Info.plist (ключ `IllUsionConfig`),
/// что позволяет задавать разные backend-домены для Debug/Release через xcconfig.
enum AppConfig {
    /// Базовый URL API.
    static let apiBaseURL: URL = {
        if let raw = Bundle.main.object(forInfoDictionaryKey: "IllUsionAPIBaseURL") as? String,
           let url = URL(string: raw), !raw.isEmpty {
            return url
        }
        #if DEBUG
        return URL(string: "http://localhost:8787")!
        #else
        return URL(string: "https://api.illusion.vpn")!
        #endif
    }()

    /// App Group для обмена данными между приложением и расширением-туннелем.
    static let appGroup = "group.com.illusion.vpn"

    /// Bundle ID расширения-туннеля.
    static let tunnelBundleID = "com.illusion.vpn.PacketTunnel"

    /// Сетевые таймауты.
    static let requestTimeout: TimeInterval = 15
    static let resourceTimeout: TimeInterval = 30

    /// Кол-во повторов для идемпотентных запросов.
    static let maxRetries = 2

    static var isDebug: Bool {
        #if DEBUG
        true
        #else
        false
        #endif
    }
}
