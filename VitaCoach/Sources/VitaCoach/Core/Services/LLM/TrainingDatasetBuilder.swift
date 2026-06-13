import Foundation

/// Формирует датасет для дальнейшего дообучения (fine-tuning) LLM на
/// результатах пользователя. Экспортирует JSONL в формате chat-сообщений,
/// совместимом с пайплайнами OpenAI / Hugging Face.
///
/// Источники сигнала для обучения:
/// 1) Диалоги с тренером с оценкой пользователя (👍/👎) — SFT + сигнал предпочтений.
/// 2) Результаты анализа техники + экспертные правила из базы знаний.
///
/// ВАЖНО: перед обучением данные следует обезличить. Здесь мы не выгружаем
/// идентификаторы; экспорт включается только при согласии пользователя.
@MainActor
final class TrainingDatasetBuilder {

    struct Example: Codable {
        struct Message: Codable { let role: String; let content: String }
        let messages: [Message]
        /// Метка качества: +1 (хороший ответ), -1 (плохой), 0 (нейтральный).
        let weight: Int
    }

    struct ExportResult {
        let url: URL
        let exampleCount: Int
    }

    /// Собирает примеры из истории диалога.
    func examples(from messages: [CoachMessage]) -> [Example] {
        let ordered = messages.sorted { $0.date < $1.date }
        var result: [Example] = []
        var pendingUser: CoachMessage?

        for message in ordered {
            switch message.role {
            case .user:
                pendingUser = message
            case .assistant:
                guard let user = pendingUser else { continue }
                result.append(Example(
                    messages: [
                        .init(role: "system", content: Self.trainerPersona),
                        .init(role: "user", content: user.content),
                        .init(role: "assistant", content: message.content)
                    ],
                    weight: message.rating
                ))
                pendingUser = nil
            case .system:
                continue
            }
        }
        return result
    }

    /// Превращает результаты анализа техники в обучающие примеры
    /// «вход (метрики углов) → экспертный разбор».
    func examples(from analyses: [TechniqueAnalysis]) -> [Example] {
        analyses.map { analysis in
            let angles = analysis.jointAngleSummary
                .map { "\($0.jointName): \(Int($0.minAngle))–\(Int($0.maxAngle))° (цель \(Int($0.targetRange.lower))–\(Int($0.targetRange.upper))°)" }
                .joined(separator: "; ")
            let prompt = "Упражнение: \(analysis.exerciseName). Повторов: \(analysis.repsDetected). Углы: \(angles). Оцени технику и дай рекомендации."
            let answer = ([analysis.coachComment] + analysis.feedback.map { "[\($0.severity.rawValue)] \($0.message) (\($0.ruleReference))" })
                .filter { !$0.isEmpty }
                .joined(separator: "\n")
            return Example(
                messages: [
                    .init(role: "system", content: Self.trainerPersona),
                    .init(role: "user", content: prompt),
                    .init(role: "assistant", content: answer)
                ],
                weight: analysis.overallScore >= 70 ? 1 : 0
            )
        }
    }

    /// Записывает JSONL во временную папку и возвращает ссылку для шеринга/выгрузки.
    func exportJSONL(examples: [Example], fileName: String = "vitacoach_finetune.jsonl") throws -> ExportResult {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        let lines = try examples.map { example -> String in
            let data = try encoder.encode(example)
            return String(data: data, encoding: .utf8) ?? ""
        }
        let content = lines.joined(separator: "\n")
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try content.data(using: .utf8)?.write(to: url, options: .atomic)
        return ExportResult(url: url, exampleCount: examples.count)
    }

    static let trainerPersona = """
    Ты — VitaCoach, доказательный ИИ-тренер. Даёшь краткие практичные рекомендации \
    по тренировкам, технике, питанию, сну и восстановлению, опираясь на ВОЗ, ACSM, NSCA \
    и рецензируемые исследования.
    """
}
