import Foundation
import Security

/// Безопасное хранилище секретов в Keychain. Поддерживает доступ из App Group,
/// чтобы расширение-туннель могло читать приватный ключ WireGuard.
enum KeychainStore {
    enum Key: String {
        case authToken = "auth.token"
        case wgPrivateKey = "wireguard.privateKey"
        case wgPublicKey = "wireguard.publicKey"
    }

    /// Используем общий keychain access group через App Group,
    /// чтобы данные были доступны и приложению, и расширению.
    private static var accessGroup: String? { nil } // задаётся через entitlements при необходимости

    @discardableResult
    static func set(_ value: String, for key: Key) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        var query = baseQuery(for: key)
        SecItemDelete(query as CFDictionary)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func get(_ key: Key) -> String? {
        var query = baseQuery(for: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    @discardableResult
    static func remove(_ key: Key) -> Bool {
        SecItemDelete(baseQuery(for: key) as CFDictionary) == errSecSuccess
    }

    private static func baseQuery(for key: Key) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.illusion.vpn",
            kSecAttrAccount as String: key.rawValue,
        ]
        if let group = accessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        return query
    }
}
