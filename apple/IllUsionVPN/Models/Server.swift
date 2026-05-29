import Foundation

/// VPN-сервер, получаемый от backend (`GET /api/servers`).
struct Server: Identifiable, Codable, Hashable {
    enum Feature: String, Codable, Hashable {
        case multihopEntry = "multihop-entry"
        case multihopExit = "multihop-exit"
        case obfuscation
        case p2p
        case streaming
    }

    enum Tier: String, Codable, Hashable {
        case free
        case premium
    }

    let id: String
    let country: String
    let countryCode: String
    let city: String
    let flag: String?
    let host: String
    let port: Int
    let load: Int
    let features: [Feature]
    let tier: Tier

    /// Замеренная задержка (мс), заполняется клиентом локально.
    var latencyMs: Int?

    var supportsMultihopEntry: Bool { features.contains(.multihopEntry) }
    var supportsMultihopExit: Bool { features.contains(.multihopExit) }

    var loadLabel: String {
        switch load {
        case ..<34: return "Низкая"
        case ..<67: return "Средняя"
        default: return "Высокая"
        }
    }
}

struct ServerListResponse: Codable {
    let servers: [Server]
}
