import Foundation
import Network

/// Замер задержки до сервера через TCP-хендшейк (RTT до установки соединения).
enum LatencyProbe {
    /// Возвращает задержку в миллисекундах или nil при таймауте/ошибке.
    static func measure(host: String, port: Int, timeout: TimeInterval = 2.0) async -> Int? {
        await withCheckedContinuation { continuation in
            let endpoint = NWEndpoint.Host(host)
            guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else {
                continuation.resume(returning: nil); return
            }
            let connection = NWConnection(host: endpoint, port: nwPort, using: .tcp)
            let start = DispatchTime.now()
            var finished = false

            func finish(_ value: Int?) {
                guard !finished else { return }
                finished = true
                connection.cancel()
                continuation.resume(returning: value)
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let elapsed = Double(DispatchTime.now().uptimeNanoseconds - start.uptimeNanoseconds)
                    finish(Int(elapsed / 1_000_000))
                case .failed, .cancelled:
                    finish(nil)
                default:
                    break
                }
            }

            connection.start(queue: .global(qos: .userInitiated))
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout) { finish(nil) }
        }
    }

    /// Параллельно меряет задержку до всех серверов и возвращает обновлённый список.
    static func rank(_ servers: [Server]) async -> [Server] {
        await withTaskGroup(of: (String, Int?).self) { group in
            for server in servers {
                group.addTask {
                    (server.id, await measure(host: server.host, port: server.port))
                }
            }
            var latencies: [String: Int] = [:]
            for await (id, ms) in group {
                if let ms { latencies[id] = ms }
            }
            return servers
                .map { server in
                    var copy = server
                    copy.latencyMs = latencies[server.id]
                    return copy
                }
                .sorted { ($0.latencyMs ?? .max) < ($1.latencyMs ?? .max) }
        }
    }
}
