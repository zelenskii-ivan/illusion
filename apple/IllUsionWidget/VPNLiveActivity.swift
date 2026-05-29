import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.1, *)
struct VPNLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: VPNActivityAttributes.self) { context in
            // Lock Screen / Notification Center.
            LockScreenView(context: context)
                .activitySystemActionForegroundColor(.cyan)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label {
                        Text(context.attributes.serverCity)
                    } icon: {
                        Image(systemName: context.state.isConnected ? "lock.shield.fill" : "lock.open")
                            .foregroundStyle(context.state.isConnected ? .green : .orange)
                    }
                    .font(.caption)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.attributes.serverFlag).font(.title3)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.statusText)
                            .font(.headline)
                            .foregroundStyle(context.state.isConnected ? .green : .primary)
                        Spacer()
                        if let since = context.state.connectedSince, context.state.isConnected {
                            Text(since, style: .timer)
                                .font(.headline.monospacedDigit())
                                .frame(maxWidth: 64)
                        }
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.isConnected ? "lock.shield.fill" : "lock.open")
                    .foregroundStyle(context.state.isConnected ? .green : .orange)
            } compactTrailing: {
                if let since = context.state.connectedSince, context.state.isConnected {
                    Text(since, style: .timer)
                        .monospacedDigit()
                        .frame(maxWidth: 44)
                }
            } minimal: {
                Image(systemName: context.state.isConnected ? "lock.shield.fill" : "lock.open")
                    .foregroundStyle(context.state.isConnected ? .green : .orange)
            }
            .keylineTint(.cyan)
        }
    }
}

@available(iOS 16.1, *)
private struct LockScreenView: View {
    let context: ActivityViewContext<VPNActivityAttributes>

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: context.state.isConnected ? "lock.shield.fill" : "lock.open")
                .font(.title)
                .foregroundStyle(context.state.isConnected ? .green : .orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("IllUsion · \(context.state.statusText)")
                    .font(.headline)
                Text("\(context.attributes.serverFlag) \(context.attributes.serverCity), \(context.attributes.serverCountry)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let since = context.state.connectedSince, context.state.isConnected {
                Text(since, style: .timer)
                    .font(.title3.monospacedDigit())
                    .frame(maxWidth: 70)
            }
        }
        .padding()
    }
}
