import SwiftUI

/// Дизайн-система IllUsion: цвета, градиенты, тени, радиусы.
enum Theme {
    static let accent = Color(red: 0.36, green: 0.78, blue: 0.99)      // голубой неон
    static let accentSecondary = Color(red: 0.55, green: 0.42, blue: 0.98) // фиолетовый
    static let success = Color(red: 0.20, green: 0.85, blue: 0.55)
    static let danger = Color(red: 0.98, green: 0.35, blue: 0.40)
    static let warning = Color(red: 0.99, green: 0.74, blue: 0.30)

    static let bgTop = Color(red: 0.05, green: 0.07, blue: 0.13)
    static let bgBottom = Color(red: 0.02, green: 0.03, blue: 0.07)
    static let card = Color.white.opacity(0.06)
    static let cardStroke = Color.white.opacity(0.10)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [bgTop, bgBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var accentGradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static let cornerRadius: CGFloat = 20
}

/// Карточка со стеклянным эффектом (glassmorphism).
struct GlassCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(16)
            .background(Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .stroke(Theme.cardStroke, lineWidth: 1)
            )
    }
}

extension View {
    func glassCard() -> some View { GlassCard { self } }
}
