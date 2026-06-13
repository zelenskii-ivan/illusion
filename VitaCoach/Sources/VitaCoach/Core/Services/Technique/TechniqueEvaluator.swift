import Foundation
import CoreGraphics

/// Оценивает технику по последовательности поз: вычисляет углы в суставах,
/// сравнивает с эталонными диапазонами из `KnowledgeBase`, считает повторы
/// и формирует обратную связь с ссылками на источники.
@MainActor
final class TechniqueEvaluator {
    private let knowledgeBase: KnowledgeBase

    init(knowledgeBase: KnowledgeBase) {
        self.knowledgeBase = knowledgeBase
    }

    func evaluate(exerciseKey: String, frames: [PoseFrame]) -> TechniqueAnalysis {
        let technique = knowledgeBase.technique(for: exerciseKey)
        let name = technique?.name ?? exerciseKey
        let rules = technique?.angleRules ?? []

        // Серии углов по каждому используемому в правилах суставу.
        var seriesByJoint: [String: [Double]] = [:]
        let neededJoints = Set(rules.map(\.jointName))
        for joint in neededJoints {
            seriesByJoint[joint] = frames.compactMap { angle(for: joint, in: $0) }
        }

        var feedback: [TechniqueFeedbackItem] = []
        var summaries: [JointAngleStat] = []
        var scoreAccumulator: [Double] = []

        for rule in rules {
            guard let series = seriesByJoint[rule.jointName], !series.isEmpty else { continue }
            let (score, value) = evaluateRule(rule, series: series)
            scoreAccumulator.append(score)

            summaries.append(JointAngleStat(
                jointName: Self.label(for: rule.jointName),
                minAngle: series.min() ?? 0,
                maxAngle: series.max() ?? 0,
                targetRange: rule.range
            ))

            if score >= 0.85 {
                feedback.append(.init(severity: .good,
                                      message: "\(Self.label(for: rule.jointName)): в норме (\(Int(value))°)",
                                      ruleReference: rule.reference))
            } else {
                feedback.append(.init(severity: score < 0.5 ? .critical : .warning,
                                      message: rule.cue,
                                      ruleReference: rule.reference))
            }
        }

        let overall = scoreAccumulator.isEmpty ? 0 : scoreAccumulator.reduce(0, +) / Double(scoreAccumulator.count) * 100
        let reps = detectReps(exerciseKey: exerciseKey, seriesByJoint: seriesByJoint)

        return TechniqueAnalysis(
            exerciseKey: exerciseKey,
            exerciseName: name,
            overallScore: overall.rounded(),
            repsDetected: reps,
            feedback: feedback.isEmpty ? [defaultFeedback] : feedback,
            jointAngleSummary: summaries
        )
    }

    // MARK: - Правила

    private func evaluateRule(_ rule: JointAngleRule, series: [Double]) -> (score: Double, value: Double) {
        switch rule.phase {
        case .bottom:
            // В нижней точке важен минимальный достигнутый угол.
            let value = series.min() ?? 0
            return (rangeScore(value, range: rule.range), value)
        case .top:
            let value = series.max() ?? 0
            return (rangeScore(value, range: rule.range), value)
        case .any:
            // Доля кадров, где сустав в допустимом диапазоне.
            let inRange = series.filter { rule.range.contains($0) }.count
            let fraction = Double(inRange) / Double(series.count)
            let representative = series.sorted(by: <)[series.count / 2] // медиана
            return (fraction, representative)
        }
    }

    private func rangeScore(_ value: Double, range: ClosedRangeBox) -> Double {
        if range.contains(value) { return 1 }
        let distance = value < range.lower ? range.lower - value : value - range.upper
        return max(0, 1 - distance / 30.0)
    }

    // MARK: - Подсчёт повторов

    private func detectReps(exerciseKey: String, seriesByJoint: [String: [Double]]) -> Int {
        let primaryJoint: String?
        switch exerciseKey {
        case "bodyweight_squat", "forward_lunge": primaryJoint = "knee"
        case "push_up": primaryJoint = "elbow"
        default: primaryJoint = nil // планка — статика
        }
        guard let joint = primaryJoint, let series = seriesByJoint[joint], series.count > 4 else { return 0 }

        guard let minV = series.min(), let maxV = series.max(), maxV - minV > 25 else { return 0 }
        let downThreshold = minV + (maxV - minV) * 0.35
        let upThreshold = minV + (maxV - minV) * 0.65

        var reps = 0
        var isDown = false
        for value in series {
            if !isDown, value < downThreshold { isDown = true }
            else if isDown, value > upThreshold { isDown = false; reps += 1 }
        }
        return reps
    }

    // MARK: - Углы

    private func angle(for joint: String, in frame: PoseFrame) -> Double? {
        func p(_ name: String) -> CGPoint? { frame.point(name) }
        switch joint {
        case "knee":
            guard let hip = p("hip"), let knee = p("knee"), let ankle = p("ankle") else { return nil }
            return PoseEstimationService.angle(hip, knee, ankle)
        case "hip":
            guard let shoulder = p("shoulder"), let hip = p("hip"), let knee = p("knee") else { return nil }
            return PoseEstimationService.angle(shoulder, hip, knee)
        case "elbow":
            guard let shoulder = p("shoulder"), let elbow = p("elbow"), let wrist = p("wrist") else { return nil }
            return PoseEstimationService.angle(shoulder, elbow, wrist)
        case "trunk":
            // Отклонение корпуса (бедро→плечо) от вертикали.
            guard let shoulder = p("shoulder"), let hip = p("hip") else { return nil }
            return PoseEstimationService.verticalDeviation(hip, shoulder)
        case "body":
            // Прямизна линии тела: угол плечо—бедро—голеностоп (≈180 = ровно).
            guard let shoulder = p("shoulder"), let hip = p("hip"), let ankle = p("ankle") else { return nil }
            return PoseEstimationService.angle(shoulder, hip, ankle)
        default:
            return nil
        }
    }

    private static func label(for joint: String) -> String {
        switch joint {
        case "knee": return "Колено"
        case "hip": return "Тазобедренный сустав"
        case "elbow": return "Локоть"
        case "trunk": return "Наклон корпуса"
        case "body": return "Линия тела"
        default: return joint
        }
    }

    private var defaultFeedback: TechniqueFeedbackItem {
        .init(severity: .warning,
              message: "Недостаточно данных о позе. Снимите упражнение сбоку, в полный рост, при хорошем освещении.",
              ruleReference: "VitaCoach")
    }
}
