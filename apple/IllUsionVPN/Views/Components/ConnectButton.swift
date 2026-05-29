import SwiftUI

/// Большая круглая кнопка подключения с анимированными пульсирующими кольцами.
struct ConnectButton: View {
    let state: ConnectionState
    let action: () -> Void

    @State private var pulse = false

    var body: some View {
        Button(action: action) {
            ZStack {
                ForEach(0..<3) { index in
                    Circle()
                        .stroke(state.tint.opacity(0.35), lineWidth: 2)
                        .scaleEffect(pulse ? 1.0 + CGFloat(index) * 0.18 : 0.9)
                        .opacity(state.isConnected && pulse ? 0 : 0.6)
                        .animation(
                            .easeOut(duration: 2).repeatForever(autoreverses: false)
                                .delay(Double(index) * 0.4),
                            value: pulse
                        )
                }

                Circle()
                    .fill(Theme.accentGradient)
                    .frame(width: 180, height: 180)
                    .shadow(color: state.tint.opacity(0.6), radius: 30)
                    .overlay(
                        Circle().stroke(.white.opacity(0.15), lineWidth: 1)
                    )

                VStack(spacing: 8) {
                    Image(systemName: state.isConnected ? "lock.fill" : "power")
                        .font(.system(size: 44, weight: .bold))
                    Text(state.isConnected ? "Отключить" : "Подключить")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundStyle(.white)

                if state.isBusy {
                    ProgressView()
                        .controlSize(.large)
                        .tint(.white)
                        .offset(y: 70)
                }
            }
            .frame(width: 280, height: 280)
        }
        .buttonStyle(.plain)
        .disabled(state.isBusy)
        .onAppear { pulse = true }
    }
}
