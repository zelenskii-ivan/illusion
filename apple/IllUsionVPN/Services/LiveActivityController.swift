#if os(iOS)
import Foundation
import ActivityKit

/// Управляет Live Activity статуса VPN (Lock Screen + Dynamic Island).
/// iOS 16.2+: используем content-based API (ActivityContent).
@available(iOS 16.2, *)
final class LiveActivityController {
    static let shared = LiveActivityController()

    private var activity: Activity<VPNActivityAttributes>?

    private var isEnabled: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    func start(server: Server, state: ConnectionState) {
        guard isEnabled, activity == nil else {
            update(state: state)
            return
        }
        let attributes = VPNActivityAttributes(
            serverCity: server.city,
            serverCountry: server.country,
            serverFlag: server.flag ?? "🌐"
        )
        let content = contentState(for: state)
        do {
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: content, staleDate: nil)
            )
        } catch {
            Log.app.error("Не удалось запустить Live Activity: \(error.localizedDescription, privacy: .public)")
        }
    }

    func update(state: ConnectionState) {
        guard let activity else { return }
        Task {
            await activity.update(.init(state: contentState(for: state), staleDate: nil))
        }
    }

    func end() {
        guard let activity else { return }
        let finalState = contentState(for: .disconnected)
        Task {
            await activity.end(.init(state: finalState, staleDate: nil), dismissalPolicy: .immediate)
        }
        self.activity = nil
    }

    private func contentState(for state: ConnectionState) -> VPNActivityAttributes.ContentState {
        var since: Date?
        if case let .connected(date) = state { since = date }
        return .init(
            statusText: state.title,
            isConnected: state.isConnected,
            connectedSince: since
        )
    }
}
#endif
