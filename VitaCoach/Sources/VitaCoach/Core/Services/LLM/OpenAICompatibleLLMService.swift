import Foundation

/// Клиент для любого OpenAI-совместимого Chat Completions API
/// (OpenAI, локальные серверы вроде Ollama/LM Studio, vLLM и т.п.).
/// Сюда же можно направить и собственную дообученную модель.
struct OpenAICompatibleLLMService: LLMService {
    struct Configuration: Sendable {
        var baseURL: String
        var apiKey: String
        var model: String
        var temperature: Double = 0.6
    }

    let configuration: Configuration
    var displayName: String { "API · \(configuration.model)" }

    func complete(messages: [LLMMessage]) async throws -> String {
        guard !configuration.apiKey.isEmpty else { throw LLMError.notConfigured }
        guard let url = URL(string: configuration.baseURL.trimmingTrailingSlash + "/chat/completions") else {
            throw LLMError.notConfigured
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")

        let payload = ChatRequest(
            model: configuration.model,
            temperature: configuration.temperature,
            messages: messages.map { .init(role: $0.role.rawValue, content: $0.content) }
        )
        request.httpBody = try JSONEncoder().encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw LLMError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw LLMError.server(message)
        }

        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else { throw LLMError.invalidResponse }
        return content
    }

    // MARK: - DTO

    private struct ChatRequest: Encodable {
        let model: String
        let temperature: Double
        let messages: [Msg]
        struct Msg: Encodable { let role: String; let content: String }
    }

    private struct ChatResponse: Decodable {
        let choices: [Choice]
        struct Choice: Decodable { let message: Msg }
        struct Msg: Decodable { let content: String }
    }
}

private extension String {
    var trimmingTrailingSlash: String {
        hasSuffix("/") ? String(dropLast()) : self
    }
}
