import SwiftUI
import SwiftData

struct WorkoutsView: View {
    @Environment(AppContainer.self) private var container
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]
    @Query(sort: \WorkoutPlan.createdAt, order: .reverse) private var plans: [WorkoutPlan]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    @State private var showLogSheet = false

    private var activePlan: WorkoutPlan? { plans.first { $0.isActive } ?? plans.first }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let plan = activePlan {
                        planCard(plan)
                        ForEach(plan.workouts.sorted { $0.order < $1.order }) { workout in
                            NavigationLink {
                                WorkoutDetailView(workout: workout)
                            } label: {
                                WorkoutRow(workout: workout)
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        EmptyStateView(systemImage: "dumbbell.fill",
                                       title: "Нет активного плана",
                                       message: "Сгенерируйте персональный план на основе вашего профиля, целей и научных рекомендаций.")
                    }

                    Button {
                        generatePlan()
                    } label: {
                        Label(activePlan == nil ? "Сгенерировать план" : "Обновить план",
                              systemImage: "wand.and.stars")
                    }
                    .buttonStyle(PrimaryButtonStyle())

                    recentSessions
                }
                .padding()
            }
            .screenBackground()
            .navigationTitle("Тренировки")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showLogSheet = true } label: { Image(systemName: "checkmark.circle") }
                }
            }
            .sheet(isPresented: $showLogSheet) {
                LogSessionView(suggested: nil)
            }
        }
    }

    private func planCard(_ plan: WorkoutPlan) -> some View {
        Card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(plan.title).font(.title3.bold()).foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Tag(text: plan.generator == .llm ? "ИИ" : "Наука",
                        tint: plan.generator == .llm ? Theme.accentSecondary : Theme.accent)
                }
                Text(plan.summary).font(.subheadline).foregroundStyle(Theme.textSecondary)
                HStack(spacing: 16) {
                    Label("\(plan.weeks) нед.", systemImage: "calendar")
                    Label("\(plan.workouts.count) дн/нед", systemImage: "repeat")
                }
                .font(.caption).foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var recentSessions: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader("Журнал тренировок", subtitle: "Последние результаты", systemImage: "list.clipboard")
            if sessions.isEmpty {
                Text("Ещё нет записанных тренировок.")
                    .font(.subheadline).foregroundStyle(Theme.textSecondary)
            } else {
                ForEach(sessions.prefix(5)) { session in
                    Card(padding: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.title).font(.subheadline.bold()).foregroundStyle(Theme.textPrimary)
                                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption).foregroundStyle(Theme.textSecondary)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text("\(session.durationMinutes) мин").foregroundStyle(Theme.textPrimary)
                                Text("RPE \(session.perceivedExertion)").font(.caption).foregroundStyle(Theme.textSecondary)
                            }
                            .font(.subheadline)
                        }
                    }
                }
            }
        }
    }

    private func generatePlan() {
        guard let profile = profiles.first else { return }
        for plan in plans where plan.isActive { plan.isActive = false }
        let plan = container.planner.makePlan(for: profile)
        context.insert(plan)
        try? context.save()
    }
}

struct WorkoutRow: View {
    let workout: PlannedWorkout

    var body: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.title).font(.headline).foregroundStyle(Theme.textPrimary)
                    Text(workout.focus).font(.caption).foregroundStyle(Theme.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(workout.estimatedMinutes) мин").font(.subheadline).foregroundStyle(Theme.accent)
                    Text("\(workout.exercises.count) упр.").font(.caption).foregroundStyle(Theme.textSecondary)
                }
                Image(systemName: "chevron.right").foregroundStyle(Theme.textSecondary)
            }
        }
    }
}
