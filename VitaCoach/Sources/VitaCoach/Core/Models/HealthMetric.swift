import Foundation
import SwiftData
import SwiftUI

/// Типы отслеживаемых метрик здоровья.
/// Пороговые значения и нормы опираются на открытые научные рекомендации
/// (ВОЗ, ACSM, AHA) — см. `KnowledgeBase`.
enum MetricType: String, Codable, CaseIterable, Identifiable {
    case steps
    case heartRate
    case restingHeartRate
    case sleepHours
    case activeEnergy
    case weight
    case waterIntake
    case vo2Max
    case bodyFat
    case mood

    var id: String { rawValue }

    var title: String {
        switch self {
        case .steps: return "Шаги"
        case .heartRate: return "Пульс"
        case .restingHeartRate: return "Пульс покоя"
        case .sleepHours: return "Сон"
        case .activeEnergy: return "Активная энергия"
        case .weight: return "Вес"
        case .waterIntake: return "Вода"
        case .vo2Max: return "VO₂max"
        case .bodyFat: return "Жир в теле"
        case .mood: return "Настроение"
        }
    }

    var unit: String {
        switch self {
        case .steps: return "шаг"
        case .heartRate, .restingHeartRate: return "уд/мин"
        case .sleepHours: return "ч"
        case .activeEnergy: return "ккал"
        case .weight: return "кг"
        case .waterIntake: return "мл"
        case .vo2Max: return "мл/кг/мин"
        case .bodyFat: return "%"
        case .mood: return "/5"
        }
    }

    var systemImage: String {
        switch self {
        case .steps: return "figure.walk"
        case .heartRate: return "heart.fill"
        case .restingHeartRate: return "heart.text.square.fill"
        case .sleepHours: return "bed.double.fill"
        case .activeEnergy: return "flame.fill"
        case .weight: return "scalemass.fill"
        case .waterIntake: return "drop.fill"
        case .vo2Max: return "lungs.fill"
        case .bodyFat: return "percent"
        case .mood: return "face.smiling.fill"
        }
    }

    var tint: Color {
        switch self {
        case .steps: return .green
        case .heartRate, .restingHeartRate: return .pink
        case .sleepHours: return .indigo
        case .activeEnergy: return .orange
        case .weight: return .teal
        case .waterIntake: return .blue
        case .vo2Max: return .mint
        case .bodyFat: return .purple
        case .mood: return .yellow
        }
    }

    /// Рекомендованная суточная норма (если применимо) для подсветки прогресса.
    var dailyTarget: Double? {
        switch self {
        case .steps: return 8000          // ВОЗ/мета-анализы: 7-9k шагов заметно снижают риски
        case .sleepHours: return 8         // AASM: 7-9 ч для взрослых
        case .activeEnergy: return 500
        case .waterIntake: return 2000
        default: return nil
        }
    }

    /// Для большинства метрик «больше — лучше», но не для всех.
    var higherIsBetter: Bool {
        switch self {
        case .restingHeartRate, .bodyFat: return false
        default: return true
        }
    }
}

/// Единичное измерение метрики.
@Model
final class MetricSample {
    var id: UUID
    var typeRaw: String
    var value: Double
    var date: Date
    var sourceRaw: String

    var type: MetricType {
        get { MetricType(rawValue: typeRaw) ?? .steps }
        set { typeRaw = newValue.rawValue }
    }

    var source: MetricSource {
        get { MetricSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }

    init(type: MetricType, value: Double, date: Date = .now, source: MetricSource = .manual) {
        self.id = UUID()
        self.typeRaw = type.rawValue
        self.value = value
        self.date = date
        self.sourceRaw = source.rawValue
    }
}

enum MetricSource: String, Codable {
    case manual
    case healthKit
    case computed
}
