import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppContainer.self) private var container
    @Query private var samples: [MetricSample]
    @Query private var profiles: [UserProfile]
    @Query(filter: #Predicate<WorkoutPlan> { $0.isActive })
    private var plans: [WorkoutPlan]

    @State private var showProfile = false
    @State private var focusMode: FocusMode = .personal
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var profile: UserProfile? { profiles.first }

    private var heroMetrics: [MetricSummary] {
        [.steps, .activeEnergy, .sleepHours, .waterIntake]
            .map { MetricsAnalytics.summary(for: $0, from: samples) }
    }

    private var todaysWorkout: PlannedWorkout? {
        let weekday = Calendar.current.component(.weekday, from: .now)
        return plans.first?.workouts
            .sorted { abs($0.dayOfWeek - weekday) < abs($1.dayOfWeek - weekday) }
            .first
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    header.appearCascade(0, reduceMotion: reduceMotion)
                    focusSection.appearCascade(1, reduceMotion: reduceMotion)
                    ringsSection.appearCascade(2, reduceMotion: reduceMotion)
                    if let workout = todaysWorkout {
                        todaysWorkoutCard(workout).appearCascade(3, reduceMotion: reduceMotion)
                    }
                    insightCard.appearCascade(4, reduceMotion: reduceMotion)
                    sourcesCard.appearCascade(5, reduceMotion: reduceMotion)
                }
                .padding()
            }
            .screenBackground()
            .navigationTitle("VitaCoach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showProfile = true } label: {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
            .sheet(isPresented: $showProfile) {
                ProfileView()
            }
        }
    }

    private var header: some View {
        Card {
            VStack(alignment: .leading, spacing: 8) {
                Text(greeting)
                    .font(.title2.bold())
                    .foregroundStyle(Theme.textPrimary)
                if let profile {
                    Text("Цель: \(profile.goal.title) · \(profile.fitnessLevel.title)")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                    HStack(spacing: 8) {
                        Tag(text: "ИМТ \(String(format: "%.1f", profile.bmi))")
                        Tag(text: "max ЧСС \(profile.estimatedMaxHeartRate)", tint: .pink)
                        Tag(text: "\(profile.weeklyWorkoutTarget)× в нед.", tint: Theme.accentSecondary)
                    }
                }
            }
        }
    }

    private var focusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Режим", subtitle: "Выберите фокус на сегодня", systemImage: "circle.hexagongrid.fill")
            VStack(spacing: 14) {
                ForEach(FocusMode.allCases) { mode in
                    LiquidButton(
                        title: mode.title,
                        systemImage: mode.systemImage,
                        tint: mode.tint,
                        isOn: focusMode == mode
                    ) {
                        Haptics.selection()
                        withAnimation(Motion.spring) { focusMode = mode }
                    }
                }
            }
        }
    }

    private var ringsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Сегодня", subtitle: "Прогресс по дневным целям", systemImage: "target")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(heroMetrics) { summary in
                    DashboardMetricCard(summary: summary)
                }
            }
        }
    }

    private func todaysWorkoutCard(_ workout: PlannedWorkout) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 12) {
                SectionHeader("Тренировка дня", subtitle: workout.focus, systemImage: "dumbbell.fill")
                Text(workout.title).font(.title3.bold()).foregroundStyle(Theme.textPrimary)
                HStack(spacing: 16) {
                    Label("\(workout.estimatedMinutes) мин", systemImage: "clock")
                    Label("\(workout.exercises.count) упр.", systemImage: "list.bullet")
                }
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var insightCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader("Совет дня", systemImage: "sparkles")
                Text(insightText)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var sourcesCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                SectionHeader("Доказательная база", subtitle: "Рекомендации опираются на науку", systemImage: "books.vertical.fill")
                ForEach(container.knowledgeBase.sources.prefix(3)) { source in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(source.title).font(.caption.bold()).foregroundStyle(Theme.textPrimary)
                        Text("\(source.organization), \(String(source.year))")
                            .font(.caption2).foregroundStyle(Theme.textSecondary)
                    }
                }
            }
        }
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        let name = profile?.name ?? "Атлет"
        switch hour {
        case 5..<12: return "Доброе утро, \(name)!"
        case 12..<18: return "Добрый день, \(name)!"
        default: return "Добрый вечер, \(name)!"
        }
    }

    private var insightText: String {
        let steps = heroMetrics.first { $0.type == .steps }
        if let steps, let target = MetricType.steps.dailyTarget, steps.latest < target * 0.5 {
            return "Сегодня мало движения. Короткая прогулка 15–20 минут поможет добрать активность. ВОЗ рекомендует ≥150 минут в неделю."
        }
        let sleep = heroMetrics.first { $0.type == .sleepHours }
        if let sleep, sleep.average7d < 7 {
            return "Средний сон за неделю ниже 7 часов. Постарайтесь раньше ложиться — это улучшит восстановление (AASM, 2015)."
        }
        return "Отличная работа! Держите регулярность — это главный фактор прогресса. Загляните к ИИ-тренеру за персональным разбором."
    }
}

struct DashboardMetricCard: View {
    let summary: MetricSummary

    var body: some View {
        Card(padding: 14) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: summary.type.systemImage)
                        .foregroundStyle(summary.type.tint)
                    Spacer()
                    if let progress = summary.targetProgress {
                        ProgressRing(progress: progress, tint: summary.type.tint, lineWidth: 5)
                            .frame(width: 26, height: 26)
                    }
                }
                Text(formatted(summary.latest))
                    .font(.title3.bold())
                    .foregroundStyle(Theme.textPrimary)
                    .contentTransition(.numericText())
                Text(summary.type.title)
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private func formatted(_ value: Double) -> String {
        if summary.type == .sleepHours { return String(format: "%.1f %@", value, summary.type.unit) }
        return "\(Int(value)) \(summary.type.unit)"
    }
}

/// Режимы фокуса для стеклянных кнопок на дашборде.
enum FocusMode: String, CaseIterable, Identifiable {
    case sleep
    case doNotDisturb
    case personal

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sleep: return "Сон"
        case .doNotDisturb: return "Не беспокоить"
        case .personal: return "Личный"
        }
    }

    var systemImage: String {
        switch self {
        case .sleep: return "bed.double.fill"
        case .doNotDisturb: return "moon.fill"
        case .personal: return "person.fill"
        }
    }

    var tint: Color {
        switch self {
        case .sleep: return Theme.accentSecondary
        case .doNotDisturb: return .indigo
        case .personal: return Theme.accent
        }
    }
}
