import SwiftUI

/// Стиль «liquid glass»-кнопки: полупрозрачный фон с размытием,
/// глянцевый блик сверху, стеклянная обводка и мягкое цветное свечение
/// в активном состоянии. Состояние `isOn` передаётся в стиль, чтобы
/// анимация подсветки и тени работала из коробки.
struct LiquidButtonStyle: ButtonStyle {
    var tint: Color = Theme.accentSecondary
    var isOn: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background(pressed: configuration.isPressed))
            .overlay(glassBorder)
            .clipShape(Capsule(style: .continuous))
            .shadow(
                color: isOn ? tint.opacity(0.55) : .black.opacity(0.35),
                radius: isOn ? 26 : 14,
                x: 0,
                y: isOn ? 2 : 10
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
            .animation(.spring(response: 0.4, dampingFraction: 0.78), value: isOn)
    }

    private func background(pressed: Bool) -> some View {
        Capsule(style: .continuous)
            .fill(.ultraThinMaterial)
            // Цветная заливка-свечение (активна) или лёгкий стеклянный градиент (неактивна).
            .overlay {
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isOn
                                ? [tint.opacity(0.6), tint.opacity(0.12)]
                                : [Color.white.opacity(0.10), Color.white.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            // Глянцевый блик в верхней части пилюли.
            .overlay(alignment: .top) {
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.65), Color.white.opacity(0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 24)
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                    .blur(radius: 3)
                    .allowsHitTesting(false)
            }
            .brightness(pressed ? -0.04 : 0)
    }

    private var glassBorder: some View {
        Capsule(style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.7),
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.04)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

/// Готовая стеклянная кнопка-пилюля с иконкой, заголовком и состоянием.
struct LiquidButton: View {
    let title: String
    let systemImage: String
    var tint: Color = Theme.accentSecondary
    var isOn: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isOn ? tint : Theme.textSecondary)
                    .frame(width: 28, height: 28)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(isOn ? Theme.textPrimary : Theme.textSecondary)

                Spacer(minLength: 0)

                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Theme.textSecondary.opacity(0.7))
            }
        }
        .buttonStyle(LiquidButtonStyle(tint: tint, isOn: isOn))
    }
}

#Preview("Liquid Buttons") {
    struct Demo: View {
        @State private var selection = "sleep"
        var body: some View {
            VStack(spacing: 16) {
                LiquidButton(title: "Сон", systemImage: "bed.double.fill",
                             tint: Theme.accentSecondary, isOn: selection == "sleep") {
                    selection = "sleep"
                }
                LiquidButton(title: "Не беспокоить", systemImage: "moon.fill",
                             tint: .indigo, isOn: selection == "dnd") {
                    selection = "dnd"
                }
                LiquidButton(title: "Личный", systemImage: "person.fill",
                             tint: Theme.accent, isOn: selection == "personal") {
                    selection = "personal"
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.backgroundGradient)
            .preferredColorScheme(.dark)
        }
    }
    return Demo()
}
