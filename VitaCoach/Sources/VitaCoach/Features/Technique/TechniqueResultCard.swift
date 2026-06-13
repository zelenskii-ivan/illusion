import SwiftUI

struct TechniqueResultCard: View {
    let analysis: TechniqueAnalysis

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    ZStack {
                        ProgressRing(progress: analysis.overallScore / 100, tint: scoreColor, lineWidth: 8)
                            .frame(width: 72, height: 72)
                        VStack(spacing: 0) {
                            Text("\(Int(analysis.overallScore))").font(.title2.bold()).foregroundStyle(Theme.textPrimary)
                            Text("балл").font(.caption2).foregroundStyle(Theme.textSecondary)
                        }
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(analysis.exerciseName).font(.headline).foregroundStyle(Theme.textPrimary)
                        Text("Распознано повторов: \(analysis.repsDetected)")
                            .font(.subheadline).foregroundStyle(Theme.textSecondary)
                        Text(verdict).font(.caption).foregroundStyle(scoreColor)
                    }
                    Spacer()
                }

                if !analysis.jointAngleSummary.isEmpty {
                    Divider().overlay(Color.white.opacity(0.1))
                    SectionHeader("Углы в суставах", systemImage: "angle")
                    ForEach(analysis.jointAngleSummary) { stat in
                        JointAngleRow(stat: stat)
                    }
                }

                Divider().overlay(Color.white.opacity(0.1))
                SectionHeader("Обратная связь", systemImage: "text.bubble")
                ForEach(analysis.feedback) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: icon(for: item.severity))
                            .foregroundStyle(color(for: item.severity))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.message).font(.subheadline).foregroundStyle(Theme.textPrimary)
                            Text(item.ruleReference).font(.caption2).foregroundStyle(Theme.textSecondary)
                        }
                    }
                }

                if !analysis.coachComment.isEmpty {
                    Divider().overlay(Color.white.opacity(0.1))
                    Label {
                        Text(analysis.coachComment).font(.subheadline).foregroundStyle(Theme.textSecondary)
                    } icon: {
                        Image(systemName: "sparkles").foregroundStyle(Theme.accent)
                    }
                }
            }
        }
    }

    private var scoreColor: Color {
        switch analysis.overallScore {
        case 80...: return .green
        case 60..<80: return .yellow
        default: return .orange
        }
    }

    private var verdict: String {
        switch analysis.overallScore {
        case 80...: return "Отличная техника"
        case 60..<80: return "Хорошо, есть нюансы"
        default: return "Нужна работа над техникой"
        }
    }

    private func icon(for severity: TechniqueFeedbackItem.Severity) -> String {
        switch severity {
        case .good: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.octagon.fill"
        }
    }

    private func color(for severity: TechniqueFeedbackItem.Severity) -> Color {
        switch severity {
        case .good: return .green
        case .warning: return .yellow
        case .critical: return .orange
        }
    }
}

struct JointAngleRow: View {
    let stat: JointAngleStat

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(stat.jointName).font(.caption.bold()).foregroundStyle(Theme.textPrimary)
                Spacer()
                Text("\(Int(stat.minAngle))–\(Int(stat.maxAngle))°")
                    .font(.caption).foregroundStyle(Theme.textSecondary)
            }
            GeometryReader { geo in
                let width = geo.size.width
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.08)).frame(height: 6)
                    Capsule().fill(Theme.accent.opacity(0.35))
                        .frame(width: max(2, x(stat.targetRange.upper, width) - x(stat.targetRange.lower, width)), height: 6)
                        .offset(x: x(stat.targetRange.lower, width))
                    Capsule().fill(Theme.accent)
                        .frame(width: max(2, x(stat.maxAngle, width) - x(stat.minAngle, width)), height: 6)
                        .offset(x: x(stat.minAngle, width))
                }
            }
            .frame(height: 6)
        }
    }

    /// Позиция угла на шкале 0...200° в пикселях.
    private func x(_ value: Double, _ width: CGFloat) -> CGFloat {
        let clamped = min(max(value, 0), 200)
        return width * CGFloat(clamped / 200.0)
    }
}
