import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var birthDate: Date
    var heightCm: Double
    var weightKg: Double
    var biologicalSexRaw: String
    var fitnessLevelRaw: String
    var goalRaw: String
    var weeklyWorkoutTarget: Int
    var availableEquipmentRaw: [String]
    var createdAt: Date

    var biologicalSex: BiologicalSex {
        get { BiologicalSex(rawValue: biologicalSexRaw) ?? .unspecified }
        set { biologicalSexRaw = newValue.rawValue }
    }

    var fitnessLevel: FitnessLevel {
        get { FitnessLevel(rawValue: fitnessLevelRaw) ?? .beginner }
        set { fitnessLevelRaw = newValue.rawValue }
    }

    var goal: FitnessGoal {
        get { FitnessGoal(rawValue: goalRaw) ?? .generalHealth }
        set { goalRaw = newValue.rawValue }
    }

    var equipment: [Equipment] {
        get { availableEquipmentRaw.compactMap(Equipment.init(rawValue:)) }
        set { availableEquipmentRaw = newValue.map(\.rawValue) }
    }

    var ageYears: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: .now).year ?? 30
    }

    /// Оценка максимального пульса по формуле Tanaka (2001): 208 − 0.7 × возраст.
    var estimatedMaxHeartRate: Int {
        Int((208.0 - 0.7 * Double(ageYears)).rounded())
    }

    /// Индекс массы тела.
    var bmi: Double {
        let h = heightCm / 100.0
        guard h > 0 else { return 0 }
        return weightKg / (h * h)
    }

    init(
        name: String = "Атлет",
        birthDate: Date = Calendar.current.date(byAdding: .year, value: -28, to: .now) ?? .now,
        heightCm: Double = 175,
        weightKg: Double = 72,
        biologicalSex: BiologicalSex = .unspecified,
        fitnessLevel: FitnessLevel = .beginner,
        goal: FitnessGoal = .generalHealth,
        weeklyWorkoutTarget: Int = 3,
        equipment: [Equipment] = [.bodyweight]
    ) {
        self.id = UUID()
        self.name = name
        self.birthDate = birthDate
        self.heightCm = heightCm
        self.weightKg = weightKg
        self.biologicalSexRaw = biologicalSex.rawValue
        self.fitnessLevelRaw = fitnessLevel.rawValue
        self.goalRaw = goal.rawValue
        self.weeklyWorkoutTarget = weeklyWorkoutTarget
        self.availableEquipmentRaw = equipment.map(\.rawValue)
        self.createdAt = .now
    }
}

enum BiologicalSex: String, Codable, CaseIterable, Identifiable {
    case male, female, unspecified
    var id: String { rawValue }
    var title: String {
        switch self {
        case .male: return "Мужской"
        case .female: return "Женский"
        case .unspecified: return "Не указан"
        }
    }
}

enum FitnessLevel: String, Codable, CaseIterable, Identifiable {
    case beginner, intermediate, advanced
    var id: String { rawValue }
    var title: String {
        switch self {
        case .beginner: return "Новичок"
        case .intermediate: return "Средний"
        case .advanced: return "Продвинутый"
        }
    }
    /// Базовый объём (множитель подходов) для прогрессии нагрузки.
    var volumeMultiplier: Double {
        switch self {
        case .beginner: return 1.0
        case .intermediate: return 1.35
        case .advanced: return 1.7
        }
    }
}

enum FitnessGoal: String, Codable, CaseIterable, Identifiable {
    case generalHealth, weightLoss, muscleGain, endurance, mobility
    var id: String { rawValue }
    var title: String {
        switch self {
        case .generalHealth: return "Общее здоровье"
        case .weightLoss: return "Снижение веса"
        case .muscleGain: return "Набор мышц"
        case .endurance: return "Выносливость"
        case .mobility: return "Мобильность"
        }
    }
}

enum Equipment: String, Codable, CaseIterable, Identifiable {
    case bodyweight, dumbbells, barbell, kettlebell, resistanceBands, pullUpBar, cardioMachine
    var id: String { rawValue }
    var title: String {
        switch self {
        case .bodyweight: return "Своё тело"
        case .dumbbells: return "Гантели"
        case .barbell: return "Штанга"
        case .kettlebell: return "Гиря"
        case .resistanceBands: return "Резинки"
        case .pullUpBar: return "Турник"
        case .cardioMachine: return "Кардио-тренажёр"
        }
    }
}
