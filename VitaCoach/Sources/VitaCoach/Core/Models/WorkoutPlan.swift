import Foundation
import SwiftData

@Model
final class WorkoutPlan {
    var id: UUID
    var title: String
    var summary: String
    var goalRaw: String
    var createdAt: Date
    var weeks: Int
    var isActive: Bool

    /// Источник плана: правило-ориентированный планировщик или LLM.
    var generatorRaw: String

    @Relationship(deleteRule: .cascade, inverse: \PlannedWorkout.plan)
    var workouts: [PlannedWorkout]

    var goal: FitnessGoal {
        get { FitnessGoal(rawValue: goalRaw) ?? .generalHealth }
        set { goalRaw = newValue.rawValue }
    }

    var generator: PlanGenerator {
        get { PlanGenerator(rawValue: generatorRaw) ?? .ruleBased }
        set { generatorRaw = newValue.rawValue }
    }

    init(
        title: String,
        summary: String,
        goal: FitnessGoal,
        weeks: Int = 4,
        generator: PlanGenerator = .ruleBased,
        workouts: [PlannedWorkout] = []
    ) {
        self.id = UUID()
        self.title = title
        self.summary = summary
        self.goalRaw = goal.rawValue
        self.weeks = weeks
        self.createdAt = .now
        self.isActive = true
        self.generatorRaw = generator.rawValue
        self.workouts = workouts
    }
}

enum PlanGenerator: String, Codable {
    case ruleBased
    case llm
}

@Model
final class PlannedWorkout {
    var id: UUID
    var title: String
    var dayOfWeek: Int          // 1...7
    var focus: String           // напр. "Ноги + ягодицы"
    var estimatedMinutes: Int
    var order: Int

    var plan: WorkoutPlan?

    @Relationship(deleteRule: .cascade, inverse: \PlannedExercise.workout)
    var exercises: [PlannedExercise]

    init(
        title: String,
        dayOfWeek: Int,
        focus: String,
        estimatedMinutes: Int,
        order: Int,
        exercises: [PlannedExercise] = []
    ) {
        self.id = UUID()
        self.title = title
        self.dayOfWeek = dayOfWeek
        self.focus = focus
        self.estimatedMinutes = estimatedMinutes
        self.order = order
        self.exercises = exercises
    }
}

@Model
final class PlannedExercise {
    var id: UUID
    var name: String
    var exerciseKey: String     // ключ для связи с KnowledgeBase / анализом техники
    var sets: Int
    var reps: Int
    var restSeconds: Int
    var tempo: String           // напр. "3-1-1"
    var notes: String
    var order: Int

    var workout: PlannedWorkout?

    init(
        name: String,
        exerciseKey: String,
        sets: Int,
        reps: Int,
        restSeconds: Int,
        tempo: String = "2-0-2",
        notes: String = "",
        order: Int
    ) {
        self.id = UUID()
        self.name = name
        self.exerciseKey = exerciseKey
        self.sets = sets
        self.reps = reps
        self.restSeconds = restSeconds
        self.tempo = tempo
        self.notes = notes
        self.order = order
    }
}
