import Foundation
import SwiftData

/// Результат анализа техники выполнения упражнения.
@Model
final class TechniqueAnalysis {
    var id: UUID
    var exerciseKey: String
    var exerciseName: String
    var date: Date
    var overallScore: Double           // 0...100
    var repsDetected: Int
    var feedback: [TechniqueFeedbackItem]
    var jointAngleSummary: [JointAngleStat]
    var coachComment: String           // заполняется LLM при наличии

    init(
        exerciseKey: String,
        exerciseName: String,
        date: Date = .now,
        overallScore: Double,
        repsDetected: Int,
        feedback: [TechniqueFeedbackItem],
        jointAngleSummary: [JointAngleStat],
        coachComment: String = ""
    ) {
        self.id = UUID()
        self.exerciseKey = exerciseKey
        self.exerciseName = exerciseName
        self.date = date
        self.overallScore = overallScore
        self.repsDetected = repsDetected
        self.feedback = feedback
        self.jointAngleSummary = jointAngleSummary
        self.coachComment = coachComment
    }
}

struct TechniqueFeedbackItem: Codable, Hashable, Identifiable {
    enum Severity: String, Codable {
        case good, warning, critical
    }
    var id: UUID = UUID()
    var severity: Severity
    var message: String
    /// Ссылка на правило/исследование, на котором основана рекомендация.
    var ruleReference: String
}

struct JointAngleStat: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var jointName: String
    var minAngle: Double
    var maxAngle: Double
    var targetRange: ClosedRangeBox
}

/// Codable-обёртка над диапазоном (ClosedRange сам по себе хранится плохо).
struct ClosedRangeBox: Codable, Hashable {
    var lower: Double
    var upper: Double
    func contains(_ value: Double) -> Bool { value >= lower && value <= upper }
}
