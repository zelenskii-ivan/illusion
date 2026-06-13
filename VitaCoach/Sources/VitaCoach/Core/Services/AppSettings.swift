import Foundation

enum LLMProvider: String, Codable, CaseIterable, Identifiable {
    case mock
    case openAICompatible
    var id: String { rawValue }
    var title: String {
        switch self {
        case .mock: return "Локальный (демо)"
        case .openAICompatible: return "OpenAI-совместимый API"
        }
    }
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
