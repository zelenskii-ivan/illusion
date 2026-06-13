import Foundation
import SwiftData

/// Первичное наполнение базы: профиль, база знаний и демо-метрики.
@MainActor
enum Seeder {
    static func seedIfNeeded(context: ModelContext, knowledgeBase: KnowledgeBase) {
        seedProfile(context)
        seedKnowledge(context, knowledgeBase: knowledgeBase)
        seedDemoMetrics(context)
        try? context.save()
    }

    private static func seedProfile(_ context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<UserProfile>())) ?? 0
        guard count == 0 else { return }
        context.insert(UserProfile())
    }

    private static func seedKnowledge(_ context: ModelContext, knowledgeBase: KnowledgeBase) {
        let count = (try? context.fetchCount(FetchDescriptor<KnowledgeEntry>())) ?? 0
        guard count == 0 else { return }

        for technique in knowledgeBase.techniques {
            let body = """
            Ключевые подсказки:
            • \(technique.cues.joined(separator: "\n• "))

            Частые ошибки:
            • \(technique.commonMistakes.joined(separator: "\n• "))
            """
            context.insert(KnowledgeEntry(
                title: "Техника: \(technique.name)",
                body: body,
                category: .technique,
                tags: [technique.category] + technique.primaryMuscles,
                sourceTitle: technique.references.joined(separator: ", "),
                sourceURL: "",
                sourceYear: 2021
            ))
        }

        for source in knowledgeBase.sources {
            context.insert(KnowledgeEntry(
                title: source.title,
                body: source.summary,
                category: .guideline,
                tags: [source.organization],
                sourceTitle: source.organization,
                sourceURL: source.url,
                sourceYear: source.year
            ))
        }
    }

    private static func seedDemoMetrics(_ context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<MetricSample>())) ?? 0
        guard count == 0 else { return }

        let calendar = Calendar.current
        for dayOffset in 0..<14 {
            guard let day = calendar.date(byAdding: .day, value: -dayOffset, to: .now) else { continue }
            let jitter = Double((dayOffset * 137) % 60) / 60.0

            context.insert(MetricSample(type: .steps, value: 6000 + jitter * 5000, date: day, source: .computed))
            context.insert(MetricSample(type: .sleepHours, value: 6.5 + jitter * 2, date: day, source: .computed))
            context.insert(MetricSample(type: .activeEnergy, value: 350 + jitter * 350, date: day, source: .computed))
            context.insert(MetricSample(type: .restingHeartRate, value: 58 + jitter * 8, date: day, source: .computed))
            context.insert(MetricSample(type: .waterIntake, value: 1200 + jitter * 1200, date: day, source: .computed))
        }
    }
}
