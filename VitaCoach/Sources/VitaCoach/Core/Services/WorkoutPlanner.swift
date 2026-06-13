import Foundation

/// Правило-ориентированный планировщик тренировок.
/// Опирается на принципы FITT и рекомендации ВОЗ/ACSM: распределяет
/// объём и интенсивность по уровню, цели и доступному инвентарю.
@MainActor
final class WorkoutPlanner {
    private let knowledgeBase: KnowledgeBase

    init(knowledgeBase: KnowledgeBase) {
        self.knowledgeBase = knowledgeBase
    }

    func makePlan(for profile: UserProfile) -> WorkoutPlan {
        let days = max(2, min(profile.weeklyWorkoutTarget, 6))
        let level = profile.fitnessLevel
        let splits = split(forDays: days, goal: profile.goal)

        var workouts: [PlannedWorkout] = []
        for (index, split) in splits.enumerated() {
            let exercises = exercises(for: split, level: level, goal: profile.goal)
            let workout = PlannedWorkout(
                title: split.title,
                dayOfWeek: dayOfWeek(forIndex: index, total: splits.count),
                focus: split.focus,
                estimatedMinutes: 15 + exercises.count * 8,
                order: index,
                exercises: exercises
            )
            workouts.append(workout)
        }

        let plan = WorkoutPlan(
            title: "\(profile.goal.title) · \(days) дн/нед",
            summary: summary(for: profile, days: days),
            goal: profile.goal,
            weeks: 4,
            generator: .ruleBased,
            workouts: workouts
        )
        return plan
    }

    // MARK: - Сплит

    private struct Split {
        let title: String
        let focus: String
        let keys: [String]   // ключи упражнений из KnowledgeBase
    }

    private func split(forDays days: Int, goal: FitnessGoal) -> [Split] {
        let fullBody = Split(title: "Всё тело", focus: "Фулбоди",
                             keys: ["bodyweight_squat", "push_up", "forward_lunge", "plank"])
        let lower = Split(title: "Низ тела", focus: "Ноги + ягодицы",
                          keys: ["bodyweight_squat", "forward_lunge", "plank"])
        let upper = Split(title: "Верх тела", focus: "Грудь + кор",
                          keys: ["push_up", "plank"])

        switch days {
        case 2: return [fullBody, fullBody]
        case 3: return [fullBody, lower, upper]
        case 4: return [lower, upper, fullBody, lower]
        default: return Array(repeating: fullBody, count: days).enumerated().map { idx, _ in
            idx % 2 == 0 ? lower : upper
        }
        }
    }

    private func exercises(for split: Split, level: FitnessLevel, goal: FitnessGoal) -> [PlannedExercise] {
        let baseSets = Int((Double(goalSets(goal)) * level.volumeMultiplier).rounded())
        let reps = goalReps(goal)
        let rest = goalRest(goal)

        return split.keys.enumerated().compactMap { order, key in
            guard let tech = knowledgeBase.technique(for: key) else { return nil }
            let isCore = tech.category == "Кор"
            return PlannedExercise(
                name: tech.name,
                exerciseKey: key,
                sets: isCore ? max(2, baseSets - 1) : baseSets,
                reps: isCore ? 0 : reps,
                restSeconds: rest,
                tempo: goal == .muscleGain ? "3-1-1" : "2-0-2",
                notes: isCore ? "Удержание \(30 + level.volumeMultiplier.rounded().toInt * 10) сек" : tech.cues.first ?? "",
                order: order
            )
        }
    }

    private func goalSets(_ goal: FitnessGoal) -> Int {
        switch goal {
        case .muscleGain: return 4
        case .weightLoss, .endurance: return 3
        case .generalHealth, .mobility: return 3
        }
    }

    private func goalReps(_ goal: FitnessGoal) -> Int {
        switch goal {
        case .muscleGain: return 10
        case .weightLoss: return 15
        case .endurance: return 20
        case .generalHealth: return 12
        case .mobility: return 12
        }
    }

    private func goalRest(_ goal: FitnessGoal) -> Int {
        switch goal {
        case .muscleGain: return 90
        case .weightLoss, .endurance: return 45
        case .generalHealth, .mobility: return 60
        }
    }

    private func dayOfWeek(forIndex index: Int, total: Int) -> Int {
        let spread = [1, 3, 5, 2, 4, 6]
        return spread[index % spread.count]
    }

    private func summary(for profile: UserProfile, days: Int) -> String {
        "\(profile.fitnessLevel.title) · \(days) тренировки в неделю. План составлен по принципам FITT и рекомендациям ВОЗ (≥150 мин активности/нед) и ACSM."
    }
}

private extension Double {
    var toInt: Int { Int(self) }
}
