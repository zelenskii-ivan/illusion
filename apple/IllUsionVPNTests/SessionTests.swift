import XCTest
@testable import IllUsionVPN

final class SessionTests: XCTestCase {
    private func makeSession(multihop: Bool) -> Session {
        var peers = [
            Session.Peer(
                publicKey: "PEER_PUB_1",
                endpoint: "ams1.illusion.example:51820",
                allowedIPs: multihop ? ["10.0.0.2/32"] : ["0.0.0.0/0", "::/0"],
                persistentKeepalive: 25
            )
        ]
        if multihop {
            peers.append(Session.Peer(
                publicKey: "PEER_PUB_2",
                endpoint: "fra1.illusion.example:51820",
                allowedIPs: ["0.0.0.0/0", "::/0"],
                persistentKeepalive: 25
            ))
        }
        return Session(
            sessionId: "s1",
            multihop: multihop,
            interface: .init(address: ["10.66.66.2/32"], dns: ["1.1.1.1"], mtu: 1420),
            peers: peers,
            expiresAt: 0
        )
    }

    func testWgQuickConfigContainsInterfaceAndPeer() {
        let config = makeSession(multihop: false).wgQuickConfig(privateKey: "PRIV_KEY")
        XCTAssertTrue(config.contains("[Interface]"))
        XCTAssertTrue(config.contains("PrivateKey = PRIV_KEY"))
        XCTAssertTrue(config.contains("Address = 10.66.66.2/32"))
        XCTAssertTrue(config.contains("DNS = 1.1.1.1"))
        XCTAssertTrue(config.contains("MTU = 1420"))
        XCTAssertTrue(config.contains("[Peer]"))
        XCTAssertTrue(config.contains("PublicKey = PEER_PUB_1"))
        XCTAssertTrue(config.contains("PersistentKeepalive = 25"))
    }

    func testMultihopProducesTwoPeers() {
        let config = makeSession(multihop: true).wgQuickConfig(privateKey: "PRIV")
        let peerCount = config.components(separatedBy: "[Peer]").count - 1
        XCTAssertEqual(peerCount, 2)
        XCTAssertTrue(config.contains("PEER_PUB_2"))
    }

    func testPrivateKeyNeverLeavesConfigBoundary() {
        // Приватный ключ должен присутствовать только в локальном конфиге.
        let session = makeSession(multihop: false)
        let config = session.wgQuickConfig(privateKey: "SECRET")
        XCTAssertTrue(config.contains("SECRET"))
        // В модели сессии (то, что приходит с сервера) приватного ключа нет.
        let mirror = Mirror(reflecting: session)
        XCTAssertFalse(mirror.children.contains { "\($0.value)".contains("SECRET") })
    }
}
