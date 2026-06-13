import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Главная", systemImage: "house.fill") }

            MetricsView()
                .tabItem { Label("Метрики", systemImage: "chart.xyaxis.line") }

            WorkoutsView()
                .tabItem { Label("Тренировки", systemImage: "dumbbell.fill") }

            TechniqueView()
                .tabItem { Label("Техника", systemImage: "figure.strengthtraining.traditional") }

            CoachView()
                .tabItem { Label("Тренер", systemImage: "sparkles") }
        }
        .tint(Theme.accent)
    }
}
