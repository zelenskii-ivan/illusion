import Foundation
import SwiftData

/// Фактически выполненная тренировка (результат).
@Model
final class WorkoutSession {
    var id: UUID
    var title: String
    var date: Date
    var durationMinutes: Int
    var perceivedExertion: Int     // RPE 1...10 (Borg CR10)
    var notes: String
    var caloriesBurned: Double

    @Relationship(deleteRule: .cascade, inverse: \LoggedExercise.session)
    var exercises: [LoggedExercise]

    init(
        title: String,
        date: Date = .now,
        durationMinutes: Int,
        perceivedExertion: Int = 5,
        notes: String = "",
        caloriesBurned: Double = 0,
        exercises: [LoggedExercise] = []
    ) {
        self.id = UUID()
        self.title = title
        self.date = date
        self.durationMinutes = durationMinutes
        self.perceivedExertion = perceivedExertion
        self.notes = notes
        self.caloriesBurned = caloriesBurned
        self.exercises = exercises
    }

    var totalVolume: Double {
        exercises.reduce(0) { $0 + $1.volume }
    }
}

@Model
final class LoggedExercise {
    var id: UUID
    var name: String
    var exerciseKey: String
    var sets: Int
    var reps: Int
    var weightKg: Double
    var order: Int

    var session: WorkoutSession?

    init(name: String, exerciseKey: String, sets: Int, reps: Int, weightKg: Double, order: Int) {
        self.id = UUID()
        self.name = name
        self.exerciseKey = exerciseKey
        self.sets = sets
        self.reps = reps
        self.weightKg = weightKg
        self.order = order
    }

    /// Тоннаж (объём нагрузки) = подходы × повторы × вес.
    var volume: Double {
        Double(sets * reps) * max(weightKg, 1)
    }
}
