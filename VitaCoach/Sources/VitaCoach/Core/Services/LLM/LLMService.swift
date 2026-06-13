import Foundation

enum LLMRole: String, Codable {
    case system, user, assistant
}

struct LLMMessage: Codable, Hashable {
    var role: LLMRole
    var content: String
}

enum LLMError: LocalizedError {
    case notConfigured
    case invalidResponse
    case server(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured: return "LLM-провайдер не настроен. Укажите API-ключ в настройках."
        case .invalidResponse: return "Некорректный ответ от модели."
        case .server(let m): return m
        }
    }
}

/// Абстракция над любым LLM-провайдером.
/// Реализации: `MockLLMService` (демо) и `OpenAICompatibleLLMService`.
protocol LLMService: Sendable {
    var displayName: String { get }
    func complete(messages: [LLMMessage]) async throws -> String
}
