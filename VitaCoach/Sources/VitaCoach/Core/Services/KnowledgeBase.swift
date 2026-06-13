import Foundation

/// Правило по углу в суставе для определённой фазы движения.
struct JointAngleRule: Codable, Hashable {
    var jointName: String          // совпадает с именами в PoseEstimationService
    var phase: MovementPhase
    var range: ClosedRangeBox
    var cue: String                // подсказка, если выходит за диапазон
    var reference: String          // источник правила
}

enum MovementPhase: String, Codable {
    case bottom        // нижняя точка
    case top           // верхняя точка
    case any           // на протяжении всего движения
}

/// Описание техники упражнения на основе открытых образовательных
/// и научных материалов (NSCA Essentials, ACSM, рецензируемые работы).
struct ExerciseTechnique: Codable, Hashable, Identifiable {
    var id: String { key }
    var key: String
    var name: String
    var category: String           // напр. "Ноги", "Грудь"
    var primaryMuscles: [String]
    var cues: [String]             // ключевые подсказки
    var commonMistakes: [String]
    var angleRules: [JointAngleRule]
    var references: [String]
}

struct ScientificSource: Codable, Hashable, Identifiable {
    var id: String { title }
    var title: String
    var organization: String
    var year: Int
    var url: String
    var summary: String
}

/// Хранилище техник и научных источников. Данные зашиты как seed и
/// дублируются в SwiftData (`KnowledgeEntry`) для RAG и датасета.
@MainActor
final class KnowledgeBase {
    let techniques: [ExerciseTechnique]
    let sources: [ScientificSource]

    init() {
        self.techniques = KnowledgeBase.seedTechniques()
        self.sources = KnowledgeBase.seedSources()
    }

    func technique(for key: String) -> ExerciseTechnique? {
        techniques.first { $0.key == key }
    }

    // MARK: - Seed: техники

    private static func seedTechniques() -> [ExerciseTechnique] {
        [
            ExerciseTechnique(
                key: "bodyweight_squat",
                name: "Приседание",
                category: "Ноги",
                primaryMuscles: ["Квадрицепсы", "Ягодичные", "Бицепс бедра"],
                cues: [
                    "Стопы на ширине плеч, носки слегка наружу",
                    "Колени по линии носков, не заваливаются внутрь",
                    "Спина нейтральная, грудь раскрыта",
                    "Опускайтесь до бедра параллельно полу или ниже"
                ],
                commonMistakes: [
                    "Колени уходят внутрь (вальгус)",
                    "Округление поясницы в нижней точке",
                    "Отрыв пяток от пола"
                ],
                angleRules: [
                    JointAngleRule(jointName: "knee", phase: .bottom,
                                   range: ClosedRangeBox(lower: 60, upper: 100),
                                   cue: "Приседайте глубже — бедро до параллели",
                                   reference: "NSCA Essentials of S&C, 4th ed."),
                    JointAngleRule(jointName: "hip", phase: .bottom,
                                   range: ClosedRangeBox(lower: 50, upper: 95),
                                   cue: "Уводите таз назад, как будто садитесь на стул",
                                   reference: "Schoenfeld 2010, J Strength Cond Res"),
                    JointAngleRule(jointName: "trunk", phase: .any,
                                   range: ClosedRangeBox(lower: 0, upper: 45),
                                   cue: "Меньше наклоняйтесь вперёд, держите грудь выше",
                                   reference: "ACSM Guidelines, 11th ed.")
                ],
                references: ["NSCA Essentials of S&C", "Schoenfeld 2010"]
            ),
            ExerciseTechnique(
                key: "push_up",
                name: "Отжимание",
                category: "Грудь",
                primaryMuscles: ["Грудные", "Трицепс", "Передняя дельта"],
                cues: [
                    "Тело в одну линию от головы до пяток",
                    "Локти под углом ~45° к корпусу",
                    "Опускайтесь до сгиба локтя ~90°",
                    "Корпус напряжён, таз не провисает"
                ],
                commonMistakes: [
                    "Провисание таза (гиперлордоз)",
                    "Локти в стороны на 90°",
                    "Неполная амплитуда"
                ],
                angleRules: [
                    JointAngleRule(jointName: "elbow", phase: .bottom,
                                   range: ClosedRangeBox(lower: 70, upper: 100),
                                   cue: "Опускайтесь ниже — локоть до ~90°",
                                   reference: "ACE Exercise Library"),
                    JointAngleRule(jointName: "body", phase: .any,
                                   range: ClosedRangeBox(lower: 160, upper: 185),
                                   cue: "Не провисайте в пояснице, напрягите пресс",
                                   reference: "NSCA Essentials of S&C")
                ],
                references: ["ACE Exercise Library", "NSCA Essentials of S&C"]
            ),
            ExerciseTechnique(
                key: "forward_lunge",
                name: "Выпад",
                category: "Ноги",
                primaryMuscles: ["Квадрицепсы", "Ягодичные"],
                cues: [
                    "Шаг вперёд, корпус вертикально",
                    "Переднее колено над голеностопом",
                    "Заднее колено почти касается пола",
                    "Оба колена ~90° в нижней точке"
                ],
                commonMistakes: [
                    "Переднее колено выходит за носок",
                    "Наклон корпуса вперёд",
                    "Колено заваливается внутрь"
                ],
                angleRules: [
                    JointAngleRule(jointName: "knee", phase: .bottom,
                                   range: ClosedRangeBox(lower: 80, upper: 100),
                                   cue: "Сгибайте колено до ~90°",
                                   reference: "NSCA Essentials of S&C"),
                    JointAngleRule(jointName: "trunk", phase: .any,
                                   range: ClosedRangeBox(lower: 0, upper: 20),
                                   cue: "Держите корпус вертикально",
                                   reference: "ACSM Guidelines, 11th ed.")
                ],
                references: ["NSCA Essentials of S&C"]
            ),
            ExerciseTechnique(
                key: "plank",
                name: "Планка",
                category: "Кор",
                primaryMuscles: ["Поперечная мышца живота", "Прямая мышца живота"],
                cues: [
                    "Локти под плечами",
                    "Тело в одну прямую линию",
                    "Таз не задран и не провисает",
                    "Дыхание ровное"
                ],
                commonMistakes: [
                    "Провисание таза",
                    "Задранный таз",
                    "Опущенная голова"
                ],
                angleRules: [
                    JointAngleRule(jointName: "body", phase: .any,
                                   range: ClosedRangeBox(lower: 165, upper: 185),
                                   cue: "Выровняйте корпус: таз не вверх и не вниз",
                                   reference: "ACE Exercise Library")
                ],
                references: ["ACE Exercise Library"]
            )
        ]
    }

    // MARK: - Seed: научные источники / рекомендации

    private static func seedSources() -> [ScientificSource] {
        [
            ScientificSource(
                title: "Глобальные рекомендации по физической активности",
                organization: "ВОЗ (WHO)",
                year: 2020,
                url: "https://www.who.int/publications/i/item/9789240015128",
                summary: "150–300 мин умеренной или 75–150 мин высокой аэробной нагрузки в неделю + силовые ≥2 раз/нед."
            ),
            ScientificSource(
                title: "ACSM's Guidelines for Exercise Testing and Prescription (11th ed.)",
                organization: "American College of Sports Medicine",
                year: 2021,
                url: "https://www.acsm.org",
                summary: "Принципы FITT, дозирование нагрузки, безопасные диапазоны интенсивности."
            ),
            ScientificSource(
                title: "Physical Activity Guidelines for Americans (2nd ed.)",
                organization: "US Dept. of Health & Human Services",
                year: 2018,
                url: "https://health.gov/paguidelines",
                summary: "Доказательная база по объёму и типу активности для разных групп."
            ),
            ScientificSource(
                title: "Resistance training volume and muscle hypertrophy (meta-analysis)",
                organization: "Schoenfeld B. et al., J Strength Cond Res",
                year: 2017,
                url: "https://pubmed.ncbi.nlm.nih.gov/27433992/",
                summary: "Связь недельного объёма подходов с гипертрофией; ≥10 подходов/группа/нед."
            ),
            ScientificSource(
                title: "Recommended Amount of Sleep for a Healthy Adult",
                organization: "AASM & Sleep Research Society",
                year: 2015,
                url: "https://pubmed.ncbi.nlm.nih.gov/26039963/",
                summary: "Взрослым рекомендуется ≥7 часов сна для оптимального здоровья."
            )
        ]
    }
}
