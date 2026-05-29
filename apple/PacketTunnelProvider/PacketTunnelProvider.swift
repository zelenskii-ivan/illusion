import NetworkExtension
import WireGuardKit
import os

/// Расширение, поднимающее WireGuard-туннель. Конфиг (формат wg-quick)
/// передаётся приложением через `providerConfiguration["wgQuickConfig"]`.
final class PacketTunnelProvider: NEPacketTunnelProvider {
    private lazy var adapter: WireGuardAdapter = {
        WireGuardAdapter(with: self) { logLevel, message in
            os_log("%{public}s", log: .default, type: .debug, message)
        }
    }()

    override func startTunnel(
        options: [String: NSObject]?,
        completionHandler: @escaping (Error?) -> Void
    ) {
        guard
            let proto = protocolConfiguration as? NETunnelProviderProtocol,
            let wgQuick = proto.providerConfiguration?["wgQuickConfig"] as? String,
            let configuration = try? TunnelConfiguration(fromWgQuickConfig: wgQuick, called: "IllUsion")
        else {
            completionHandler(PacketTunnelError.invalidConfiguration)
            return
        }

        adapter.start(tunnelConfiguration: configuration) { error in
            completionHandler(error)
        }
    }

    override func stopTunnel(
        with reason: NEProviderStopReason,
        completionHandler: @escaping () -> Void
    ) {
        adapter.stop { _ in completionHandler() }
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        guard let command = String(data: messageData, encoding: .utf8) else {
            completionHandler?(nil); return
        }
        switch command {
        case "getStats":
            // Runtime-конфигурация WireGuard содержит счётчики rx/tx (last handshake, transfer).
            adapter.getRuntimeConfiguration { config in
                completionHandler?(config?.data(using: .utf8))
            }
        default:
            completionHandler?(nil)
        }
    }
}

enum PacketTunnelError: Error {
    case invalidConfiguration
}
