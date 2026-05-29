import Foundation

/// Пользовательские настройки и переключатели продвинутых функций.
/// Сохраняются в общий App Group, чтобы расширение-туннель тоже имело доступ.
struct AppSettings: Codable, Equatable {
    var killSwitch: Bool = true
    var autoConnectUntrustedWiFi: Bool = false
    var alwaysOn: Bool = false
    var multihopEnabled: Bool = false
    var obfuscationEnabled: Bool = false
    var blockAdsAndTrackers: Bool = true
    var customDNS: String = ""
    /// Bundle ID приложений, исключённых из туннеля (split tunneling).
    var splitTunnelExcludedApps: [String] = []
    var preferredProtocolMTU: Int = 1420

    static let `default` = AppSettings()
}

/// Доступ к общему хранилищу настроек между приложением и расширением.
enum SettingsStore {
    static let appGroup = "group.com.illusion.vpn"
    private static let key = "app.settings"

    static func load() -> AppSettings {
        guard
            let defaults = UserDefaults(suiteName: appGroup),
            let data = defaults.data(forKey: key),
            let settings = try? JSONDecoder().decode(AppSettings.self, from: data)
        else {
            return .default
        }
        return settings
    }

    static func save(_ settings: AppSettings) {
        guard let defaults = UserDefaults(suiteName: appGroup) else { return }
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: key)
        }
    }
}
