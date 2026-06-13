import SwiftUI

/// Акцентная сцена празднования (раздел 3.5 ТЗ): частицы + вспышка,
/// пружинное появление бейджа, тактильная отдача на пике. Самодостаточна
/// (~2.6 с), пропускается тапом. Учитывает «Уменьшение движения».
struct CelebrationView: View {
    var title: String = "Готово!"
    var subtitle: String = "Тренировка записана"
    var onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var badgeIn = false
    @State private var flash = false
    @State private var finished = false
    private let start = Date.now

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()

            // Вспышка света за бейджем.
            Circle()
                .fill(Theme.accent.opacity(0.35))
                .frame(width: 320, height: 320)
                .blur(radius: 60)
                .scaleEffect(flash ? 1.2 : 0.3)
                .opacity(flash ? 0 : 0.9)

            if !reduceMotion {
                ConfettiCanvas(start: start)
            }

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Theme.accentGradient)
                        .frame(width: 112, height: 112)
                        .shadow(color: Theme.accent.opacity(0.6), radius: 24)
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .bold))
                        .foregroundStyle(.black)
                }
                .scaleEffect(badgeIn ? 1 : 0.2)
                .opacity(badgeIn ? 1 : 0)

                Text(title)
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .opacity(badgeIn ? 1 : 0)
        }
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .transition(.opacity)
        .onAppear {
            Haptics.success()
            withAnimation(reduceMotion ? .easeOut(duration: 0.3) : Motion.celebration) {
                badgeIn = true
            }
            withAnimation(.easeOut(duration: 0.8)) { flash = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + (reduceMotion ? 1.2 : 2.6)) {
                finish()
            }
        }
    }

    private func finish() {
        guard !finished else { return }
        finished = true
        onDismiss()
    }
}

/// Лёгкая система частиц на `Canvas` + `TimelineView` — без сторонних движков.
private struct ConfettiCanvas: View {
    let start: Date
    private let particles: [Particle] = (0..<90).map { _ in Particle() }

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince(start)
            Canvas { context, size in
                let originX = size.width / 2
                let originY = size.height * 0.42
                for p in particles {
                    let x = originX + p.vx * t * 90
                    let y = originY + p.vy * t * 90 + 0.5 * 420 * t * t
                    let life = max(0, 1 - t / 2.4)
                    if life <= 0 { continue }
                    context.opacity = life
                    let rect = CGRect(x: x, y: y, width: p.size, height: p.size)
                    context.fill(
                        Path(roundedRect: rect, cornerRadius: p.size / 3),
                        with: .color(p.color)
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }

    private struct Particle {
        let angle = Double.random(in: 0 ..< (2 * .pi))
        let speed = Double.random(in: 1.6 ... 5.2)
        let size = Double.random(in: 6 ... 13)
        let color = [Color.mint, .blue, .green, .cyan, .white, .teal, .indigo].randomElement()!
        var vx: Double { cos(angle) * speed }
        var vy: Double { sin(angle) * speed - 4.2 } // начальный импульс вверх
    }
}
