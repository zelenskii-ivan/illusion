import Foundation
import os

/// Централизованное логирование на базе unified logging (`os.Logger`).
/// Чувствительные данные (ключи, токены) НИКОГДА не логируются в открытом виде.
enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.illusion.vpn"

    static let tunnel = Logger(subsystem: subsystem, category: "tunnel")
    static let network = Logger(subsystem: subsystem, category: "network")
    static let auth = Logger(subsystem: subsystem, category: "auth")
    static let app = Logger(subsystem: subsystem, category: "app")
}
