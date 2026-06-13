import Foundation

enum LLMProvider: String, Codable, CaseIterable, Identifiable {
    case mock
    case groq
    case openRouter
    case openAICompatible

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mock: return "Локальный (демо, офлайн)"
        case .groq: return "Groq · бесплатно"
        case .openRouter: return "OpenRouter · есть бесплатные"
        case .openAICompatible: return "Свой OpenAI-совместимый"
        }
    }

    /// Базовый URL пресета (nil — задаёт пользователь вручную).
    var defaultBaseURL: String? {
        switch self {
        case .groq: return "https://api.groq.com/openai/v1"
        case .openRouter: return "https://openrouter.ai/api/v1"
        default: return nil
        }
    }

    /// Бесплатная модель по умолчанию для пресета.
    var defaultModel: String? {
        switch self {
        case .groq: return "llama-3.3-70b-versatile"
        case .openRouter: return "meta-llama/llama-3.3-70b-instruct:free"
        default: return nil
        }
    }

    /// Где бесплатно получить API-ключ.
    var apiKeyURL: URL? {
        switch self {
        case .groq: return URL(string: "https://console.groq.com/keys")
        case .openRouter: return URL(string: "https://openrouter.ai/keys")
        default: return nil
        }
    }

    var requiresAPIKey: Bool { self != .mock }
    var isCustomEndpoint: Bool { self == .openAICompatible }
}

/// Пользовательские настройки, включая конфигурацию LLM-провайдера.
/// Ключ API хранится в UserDefaults для демо; в продакшене — в Keychain.
struct AppSettings: Codable {
    var llmProvider: LLMProvider = .mock
    var llmBaseURL: String = "https://api.openai.com/v1"
    var llmModel: String = "gpt-4o-mini"
    var llmAPIKey: String = ""
    var allowDatasetCollection: Bool = true
    var healthKitEnabled: Bool = false

    private static let key = "VitaCoach.AppSettings"

    static func load() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings()
        }
        return decoded
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: AppSettings.key)
        }
    }
}
