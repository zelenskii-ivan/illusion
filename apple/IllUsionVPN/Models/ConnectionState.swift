import SwiftUI

/// Состояние VPN-туннеля для отображения в UI.
enum ConnectionState: Equatable {
    case disconnected
    case connecting
    case connected(since: Date)
    case disconnecting
    case failed(String)

    var title: String {
        switch self {
        case .disconnected: return NSLocalizedString("Не защищено", comment: "")
        case .connecting: return NSLocalizedString("Подключение…", comment: "")
        case .connected: return NSLocalizedString("Защищено", comment: "")
        case .disconnecting: return NSLocalizedString("Отключение…", comment: "")
        case .failed: return NSLocalizedString("Ошибка", comment: "")
        }
    }

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    var isBusy: Bool {
        self == .connecting || self == .disconnecting
    }

    var tint: Color {
        switch self {
        case .connected: return Theme.success
        case .connecting, .disconnecting: return Theme.warning
        case .failed: return Theme.danger
        case .disconnected: return .white.opacity(0.6)
        }
    }
}
