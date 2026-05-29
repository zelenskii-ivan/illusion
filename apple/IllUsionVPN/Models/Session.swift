import Foundation

/// WireGuard-сессия, выдаваемая backend (`POST /api/session`).
struct Session: Codable {
    struct Interface: Codable {
        let address: [String]
        let dns: [String]
        let mtu: Int
    }

    struct Peer: Codable {
        let publicKey: String
        let endpoint: String
        let allowedIPs: [String]
        let persistentKeepalive: Int?
    }

    let sessionId: String
    let multihop: Bool?
    let interface: Interface
    let peers: [Peer]
    let expiresAt: Double

    /// Сборка конфигурации в формате wg-quick (`[Interface]` / `[Peer]`).
    /// `privateKey` генерируется и хранится на устройстве, не уходит на сервер.
    func wgQuickConfig(privateKey: String) -> String {
        var lines: [String] = []
        lines.append("[Interface]")
        lines.append("PrivateKey = \(privateKey)")
        lines.append("Address = \(interface.address.joined(separator: ", "))")
        lines.append("DNS = \(interface.dns.joined(separator: ", "))")
        lines.append("MTU = \(interface.mtu)")
        for peer in peers {
            lines.append("")
            lines.append("[Peer]")
            lines.append("PublicKey = \(peer.publicKey)")
            lines.append("Endpoint = \(peer.endpoint)")
            lines.append("AllowedIPs = \(peer.allowedIPs.joined(separator: ", "))")
            if let keepalive = peer.persistentKeepalive {
                lines.append("PersistentKeepalive = \(keepalive)")
            }
        }
        return lines.joined(separator: "\n")
    }
}
