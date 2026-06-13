import SwiftUI

/// Единая дизайн-тема приложения.
enum Theme {
    static let accent = Color(red: 0.36, green: 0.92, blue: 0.71)      // мятно-зелёный
    static let accentSecondary = Color(red: 0.38, green: 0.62, blue: 1.0)

    static let background = Color(red: 0.05, green: 0.06, blue: 0.09)
    static let surface = Color(red: 0.10, green: 0.11, blue: 0.15)
    static let surfaceElevated = Color(red: 0.14, green: 0.15, blue: 0.20)

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.62)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [background, Color(red: 0.07, green: 0.09, blue: 0.14)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var accentGradient: LinearGradient {
        LinearGradient(colors: [accent, accentSecondary], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static let corner: CGFloat = 20
    static let spacing: CGFloat = 16
}
