import SwiftUI

/// Единая система параметров движения (motion-токены) по ТЗ:
/// длительности, кривые и пружины переиспользуются во всём приложении.
enum Motion {
    // MARK: Длительности
    static let micro: Double = 0.16        // нажатие кнопки, тоггл (120–180 мс)
    static let screen: Double = 0.45       // переход между экранами (350–500 мс)
    static let celebrationTime: Double = 1.0

    // MARK: Кривые / пружины
    /// Базовый ease-out: быстрый старт, мягкое торможение (~cubic-bezier(0.22,1,0.36,1)).
    static let easeOut = Animation.timingCurve(0.22, 1, 0.36, 1, duration: screen)
    /// Появление «живого» материала: лёгкий овершут.
    static let spring = Animation.spring(response: 0.4, dampingFraction: 0.75)
    /// Микро-отклик.
    static let microSpring = Animation.spring(response: 0.18, dampingFraction: 0.72)
    /// Празднования: выраженный овершут и отскок.
    static let celebration = Animation.spring(response: 0.5, dampingFraction: 0.55)

    /// Шаг каскадного появления карточек (40–60 мс).
    static let cascadeStep: Double = 0.05

    /// Учитывает системную настройку «Уменьшение движения»: крупные
    /// перемещения заменяются плавным кроссфейдом.
    static func adaptive(_ animation: Animation, reduceMotion: Bool,
                         fallback: Animation = .easeInOut(duration: 0.25)) -> Animation {
        reduceMotion ? fallback : animation
    }
}

// MARK: - Каскадное появление (staggered)

private struct CascadeAppear: ViewModifier {
    let index: Int
    let reduceMotion: Bool
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown ? 0 : (reduceMotion ? 0 : 18))
            .onAppear {
                let anim = reduceMotion ? .easeOut(duration: 0.3) : Motion.spring
                withAnimation(anim.delay(Double(index) * Motion.cascadeStep)) { shown = true }
            }
    }
}

// MARK: - Прочерчивание графика (left-to-right reveal)

private struct ChartReveal: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var progress: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .mask(alignment: .leading) {
                GeometryReader { geo in
                    Rectangle().frame(width: geo.size.width * progress)
                }
            }
            .onAppear {
                if reduceMotion {
                    progress = 1
                } else {
                    withAnimation(.easeInOut(duration: 0.9)) { progress = 1 }
                }
            }
    }
}

// MARK: - Нажатие карточки/строки

/// Стиль кнопки с лёгким «вдавливанием» (scale 0.97) и пружинным возвратом.
struct PressableCardStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(Motion.microSpring, value: configuration.isPressed)
    }
}

// MARK: - Shimmer (skeleton-плейсхолдеры)

private struct Shimmer: ViewModifier {
    let active: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        guard active else { return AnyView(content) }
        return AnyView(
            content
                .overlay {
                    if !reduceMotion {
                        GeometryReader { geo in
                            LinearGradient(
                                colors: [.clear, Color.white.opacity(0.35), .clear],
                                startPoint: .leading, endPoint: .trailing
                            )
                            .frame(width: geo.size.width)
                            .offset(x: phase * geo.size.width)
                            .blendMode(.plusLighter)
                        }
                    }
                }
                .mask(content)
                .onAppear {
                    guard !reduceMotion else { return }
                    withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                        phase = 1.4
                    }
                }
        )
    }
}

extension View {
    /// Каскадное появление с задержкой по индексу (учитывает Reduce Motion).
    func appearCascade(_ index: Int, reduceMotion: Bool) -> some View {
        modifier(CascadeAppear(index: index, reduceMotion: reduceMotion))
    }

    /// Эффект мерцания для skeleton-плейсхолдеров.
    func shimmering(_ active: Bool = true) -> some View {
        modifier(Shimmer(active: active))
    }

    /// «Прочерчивание» графика слева направо при появлении (раздел 3.6).
    func chartReveal() -> some View {
        modifier(ChartReveal())
    }

    // MARK: Shared-element (нативный zoom, iOS 18+), с деградацией на iOS 17.

    @ViewBuilder
    func heroSource(id: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            self.matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }

    @ViewBuilder
    func heroZoom(id: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            self.navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            self
        }
    }
}
