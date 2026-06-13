import Foundation

/// Собирает системный промпт для ИИ-тренера: личность модели + контекст
/// пользователя (профиль, метрики) + релевантные выдержки из базы знаний (RAG-lite).
@MainActor
struct LLMPromptBuilder {
    let knowledgeBase: KnowledgeBase

    func systemPrompt(profile: UserProfile?, summaries: [MetricSummary], query: String) -> String {
        var parts: [String] = []

        parts.append("""
        Ты — VitaCoach, ИИ-тренер по здоровому образу жизни. Отвечай кратко, дружелюбно и \
        по делу, на русском. Давай практичные рекомендации и всегда опирайся на доказательные \
        источники (ВОЗ, ACSM, NSCA, рецензируемые исследования). Не давай медицинских диагнозов; \
        при тревожных симптомах советуй обратиться к врачу.
        """)

        if let profile {
            parts.append("""
            ПРОФИЛЬ:
            • Возраст: \(profile.ageYears), пол: \(profile.biologicalSex.title)
            • Рост/вес: \(Int(profile.heightCm)) см / \(Int(profile.weightKg)) кг, ИМТ: \(String(format: "%.1f", profile.bmi))
            • Уровень: \(profile.fitnessLevel.title), цель: \(profile.goal.title)
            • Тренировок в неделю (план): \(profile.weeklyWorkoutTarget)
            • Инвентарь: \(profile.equipment.map(\.title).joined(separator: ", "))
            • Расчётный max ЧСС: \(profile.estimatedMaxHeartRate)
            """)
        }

        if !summaries.isEmpty {
            let lines = summaries.map { s in
                let trend = s.trend >= 0 ? "▲" : "▼"
                return "• \(s.type.title): \(String(format: "%.0f", s.latest)) \(s.type.unit) (7д: \(String(format: "%.0f", s.average7d)), \(trend)\(String(format: "%.0f%%", abs(s.trend) * 100)))"
            }
            parts.append("ПОСЛЕДНИЕ МЕТРИКИ:\n" + lines.joined(separator: "\n"))
        }

        let relevant = retrieve(for: query)
        if !relevant.isEmpty {
            let kb = relevant.map { "• [\($0.organization), \($0.year)] \($0.title): \($0.summary)" }
            parts.append("РЕЛЕВАНТНЫЕ ИСТОЧНИКИ:\n" + kb.joined(separator: "\n"))
        }

        return parts.joined(separator: "\n\n")
    }

    /// Простой лексический поиск по источникам (заглушка под векторный RAG).
    private func retrieve(for query: String, limit: Int = 3) -> [ScientificSource] {
        let q = query.lowercased()
        let tokens = Set(q.split(whereSeparator: { !$0.isLetter }).map(String.init))
        let scored = knowledgeBase.sources.map { source -> (ScientificSource, Int) in
            let haystack = (source.title + " " + source.summary + " " + source.organization).lowercased()
            let score = tokens.reduce(0) { $0 + (haystack.contains($1) ? 1 : 0) }
            return (source, score)
        }
        let hits = scored.filter { $0.1 > 0 }.sorted { $0.1 > $1.1 }.prefix(limit).map(\.0)
        return hits.isEmpty ? Array(knowledgeBase.sources.prefix(2)) : Array(hits)
    }
}
