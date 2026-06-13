import SwiftUI

/// Карточка-контейнер с фоном поверхности и скруглением.
struct Card<Content: View>: View {
    var padding: CGFloat = Theme.spacing
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.corner, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.corner, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String?
    var systemImage: String?

    init(_ title: String, subtitle: String? = nil, systemImage: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }

    var body: some View {
        HStack(spacing: 10) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(Theme.accent)
                    .font(.headline)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(Theme.textPrimary)
                if let subtitle {
                    Text(subtitle).font(.caption).foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer()
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(Color.black)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Theme.accentGradient, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct Tag: View {
    let text: String
    var tint: Color = Theme.accent
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tint.opacity(0.18), in: Capsule())
            .foregroundStyle(tint)
    }
}

/// Кольцевой индикатор прогресса к цели.
struct ProgressRing: View {
    let progress: Double
    var tint: Color = Theme.accent
    var lineWidth: CGFloat = 8

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animated: Double = 0
    private var clamped: Double { min(max(progress, 0), 1) }

    var body: some View {
        ZStack {
            Circle().stroke(tint.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: animated)
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                // Свечение при достижении цели.
                .shadow(color: clamped >= 1 ? tint.opacity(0.8) : .clear,
                        radius: clamped >= 1 ? lineWidth * 0.9 : 0)
        }
        .onAppear { animate(to: clamped) }
        .onChange(of: clamped) { _, new in animate(to: new) }
    }

    private func animate(to value: Double) {
        withAnimation(reduceMotion ? .easeOut(duration: 0.3) : Motion.spring) {
            animated = value
        }
    }
}

struct EmptyStateView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 44))
                .foregroundStyle(Theme.accent)
            Text(title).font(.headline).foregroundStyle(Theme.textPrimary)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

extension View {
    /// Применяет тёмный градиентный фон на всю область.
    func screenBackground() -> some View {
        background(Theme.backgroundGradient.ignoresSafeArea())
    }
}
