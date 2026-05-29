import Foundation

/// Счётчики трафика туннеля (получены из runtime-конфигурации WireGuard).
struct TunnelStats: Equatable {
    var rxBytes: UInt64 = 0
    var txBytes: UInt64 = 0

    /// Парсит формат `getRuntimeConfiguration` (строки `rx_bytes=` / `tx_bytes=`).
    static func parse(_ runtimeConfig: String) -> TunnelStats {
        var stats = TunnelStats()
        for line in runtimeConfig.split(separator: "\n") {
            let parts = line.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else { continue }
            let key = parts[0].trimmingCharacters(in: .whitespaces)
            let value = UInt64(parts[1].trimmingCharacters(in: .whitespaces)) ?? 0
            switch key {
            case "rx_bytes": stats.rxBytes += value
            case "tx_bytes": stats.txBytes += value
            default: break
            }
        }
        return stats
    }

    var rxFormatted: String { Self.format(rxBytes) }
    var txFormatted: String { Self.format(txBytes) }

    static func format(_ bytes: UInt64) -> String {
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var unit = 0
        while value >= 1024 && unit < units.count - 1 {
            value /= 1024; unit += 1
        }
        return String(format: unit == 0 ? "%.0f %@" : "%.1f %@", value, units[unit])
    }
}
