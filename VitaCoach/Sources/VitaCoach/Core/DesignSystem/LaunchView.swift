import SwiftUI

/// Сплэш, который «оживает» и плавно перетекает в приложение —
/// без чёрного мигания (раздел 3.1 ТЗ). Лого пульсирует, затем сцена
/// растворяется. Учитывает «Уменьшение движения».
struct LaunchView: View {
    var onFinish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appear = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            Theme.backgroundGradient.ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(Theme.accent.opacity(0.18))
                        .frame(width: 160, height: 160)
                        .scaleEffect(pulse ? 1.15 : 0.85)
                    Image(systemName: "heart.fill")
                        .font(.system(size: 84))
                        .foregroundStyle(Theme.accentGradient)
                        .shadow(color: Theme.accent.opacity(0.6), radius: 28)
                        .scaleEffect(appear ? 1 : 0.6)
                }
                Text("VitaCoach")
                    .font(.title.bold())
                    .foregroundStyle(Theme.textPrimary)
                    .opacity(appear ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(reduceMotion ? .easeOut(duration: 0.3) : Motion.spring) { appear = true }
            if !reduceMotion {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { pulse = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 0.5 : 1.2)) {
                onFinish()
            }
        }
    }
}
