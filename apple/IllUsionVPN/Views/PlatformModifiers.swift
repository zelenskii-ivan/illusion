import SwiftUI

/// Кросс-платформенные обёртки над модификаторами, которые существуют только
/// на iOS. На macOS они становятся no-op, чтобы один и тот же набор вью
/// компилировался для обеих платформ.
extension View {
    /// Стиль постраничного TabView (только iOS; на macOS — обычный TabView).
    @ViewBuilder
    func pagedTabStyle() -> some View {
        #if os(iOS)
        self
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        #else
        self
        #endif
    }

    /// Компактный заголовок навигации (iOS). На macOS — без изменений.
    @ViewBuilder
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// Крупный заголовок навигации (iOS). На macOS — без изменений.
    @ViewBuilder
    func largeNavigationTitle() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.large)
        #else
        self
        #endif
    }

    /// Отключение автокапитализации текстового поля (iOS-only API).
    @ViewBuilder
    func noAutocapitalization() -> some View {
        #if os(iOS)
        self.textInputAutocapitalization(.never)
        #else
        self
        #endif
    }

    /// Email-клавиатура (iOS). На macOS — без изменений.
    @ViewBuilder
    func emailKeyboard() -> some View {
        #if os(iOS)
        self.keyboardType(.emailAddress)
        #else
        self
        #endif
    }
}
