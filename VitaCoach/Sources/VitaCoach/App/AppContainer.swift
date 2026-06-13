import Foundation
import SwiftData
import Observation

/// Корневой контейнер зависимостей приложения (простая ручная DI).
/// Хранит общий `ModelContainer` SwiftData и все сервисы.
@MainActor
@Observable
final class AppContainer {
    let modelContainer: ModelContainer

    let healthKit: HealthKitService
    let knowledgeBase: KnowledgeBase
    let planner: WorkoutPlanner
    let poseEstimator: PoseEstimationService
    let techniqueEvaluator: TechniqueEvaluator
    let datasetBuilder: TrainingDatasetBuilder

    /// Активный LLM-провайдер. По умолчанию — локальный мок, который
    /// можно заменить реальным провайдером в настройках.
    var llm: any LLMService

    var settings: AppSettings

    init() {
        let container = AppContainer.makeModelContainer()
        self.modelContainer = container

        let knowledge = KnowledgeBase()
        self.knowledgeBase = knowledge
        self.healthKit = HealthKitService()
        self.planner = WorkoutPlanner(knowledgeBase: knowledge)
        self.poseEstimator = PoseEstimationService()
        self.techniqueEvaluator = TechniqueEvaluator(knowledgeBase: knowledge)
        self.datasetBuilder = TrainingDatasetBuilder()

        let settings = AppSettings.load()
        self.settings = settings
        self.llm = AppContainer.makeLLM(for: settings)
    }

    private var didSeed = false

    /// Первичное наполнение базы. Вызывается из `RootView` через `.task`
    /// уже после первого кадра, чтобы тяжёлый сидинг не блокировал главный
    /// поток на старте и не задерживал отрисовку UI (иначе виден белый экран).
    func seedInitialDataIfNeeded() {
        guard !didSeed else { return }
        didSeed = true
        Seeder.seedIfNeeded(context: modelContainer.mainContext, knowledgeBase: knowledgeBase)
    }

    func updateLLMProvider() {
        settings.save()
        llm = AppContainer.makeLLM(for: settings)
    }

    private static func makeLLM(for settings: AppSettings) -> any LLMService {
        switch settings.llmProvider {
        case .mock:
            return MockLLMService()
        case .openAICompatible:
            return OpenAICompatibleLLMService(
                configuration: .init(
                    baseURL: settings.llmBaseURL,
                    apiKey: settings.llmAPIKey,
                    model: settings.llmModel
                )
            )
        }
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            UserProfile.self,
            MetricSample.self,
            WorkoutPlan.self,
            PlannedWorkout.self,
            PlannedExercise.self,
            WorkoutSession.self,
            LoggedExercise.self,
            TechniqueAnalysis.self,
            CoachMessage.self,
            KnowledgeEntry.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Фолбэк на in-memory, чтобы приложение не падало при миграциях во время разработки.
            // Ошибку логируем явно — иначе сбой стора маскируется и его трудно диагностировать.
            print("⚠️ VitaCoach: не удалось открыть постоянное хранилище SwiftData, переключаюсь на in-memory. Ошибка: \(error)")
            let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [memoryConfig])
            } catch {
                fatalError("VitaCoach: не удалось создать даже in-memory ModelContainer: \(error)")
            }
        }
    }
}
