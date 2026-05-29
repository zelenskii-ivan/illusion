import Foundation

/// Клиент backend API. Базовый URL берётся из `AppConfig` (Debug/Release).
actor APIClient {
    static let shared = APIClient()

    private let baseURL: URL
    private let session: URLSession
    private let decoder = JSONDecoder()
    private var token: String?

    init() {
        baseURL = AppConfig.apiBaseURL
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConfig.requestTimeout
        config.timeoutIntervalForResource = AppConfig.resourceTimeout
        config.waitsForConnectivity = true
        session = URLSession(configuration: config)
        token = KeychainStore.get(.authToken)
    }

    struct LoginResponse: Codable {
        let token: String
        struct User: Codable { let email: String; let plan: String }
        let user: User
    }

    var isAuthenticated: Bool { token != nil }

    func setToken(_ token: String?) {
        self.token = token
        if let token { KeychainStore.set(token, for: .authToken) }
        else { KeychainStore.remove(.authToken) }
    }

    func login(email: String, password: String) async throws -> LoginResponse {
        let response: LoginResponse = try await post(
            "/api/auth/login",
            body: ["email": email, "password": password],
            authorized: false,
            retryable: false
        )
        setToken(response.token)
        return response
    }

    func logout() {
        setToken(nil)
    }

    func fetchServers() async throws -> [Server] {
        let response: ServerListResponse = try await get("/api/servers")
        return response.servers
    }

    func createSession(serverId: String, exitServerId: String?, publicKey: String) async throws -> Session {
        var body: [String: Any] = ["serverId": serverId, "publicKey": publicKey]
        if let exitServerId { body["exitServerId"] = exitServerId }
        return try await post("/api/session", body: body, retryable: false)
    }

    // MARK: - Transport

    private func get<T: Decodable>(_ path: String) async throws -> T {
        try await send(request(path, method: "GET"), retryable: true)
    }

    private func post<T: Decodable>(
        _ path: String, body: [String: Any],
        authorized: Bool = true, retryable: Bool = false
    ) async throws -> T {
        var req = request(path, method: "POST", authorized: authorized)
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        return try await send(req, retryable: retryable)
    }

    private func request(_ path: String, method: String, authorized: Bool = true) -> URLRequest {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = method
        if authorized, let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    /// Отправка с повторами (экспоненциальная задержка) для идемпотентных запросов.
    private func send<T: Decodable>(_ request: URLRequest, retryable: Bool) async throws -> T {
        var attempt = 0
        while true {
            do {
                let (data, response) = try await session.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }
                switch http.statusCode {
                case 200..<300:
                    do { return try decoder.decode(T.self, from: data) }
                    catch { throw APIError.decoding }
                case 401:
                    setToken(nil)
                    throw APIError.unauthorized
                case 429, 500...599:
                    throw APIError.server(http.statusCode)
                default:
                    throw APIError.badStatus(http.statusCode)
                }
            } catch let error as APIError {
                guard retryable, attempt < AppConfig.maxRetries, error.isRetryable else {
                    Log.network.error("Запрос не удался: \(error.localizedDescription, privacy: .public)")
                    throw error
                }
                attempt += 1
                try? await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt)) * 200_000_000))
            } catch {
                guard retryable, attempt < AppConfig.maxRetries else {
                    throw APIError.transport(error.localizedDescription)
                }
                attempt += 1
                try? await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt)) * 200_000_000))
            }
        }
    }
}

enum APIError: LocalizedError {
    case badStatus(Int)
    case server(Int)
    case unauthorized
    case invalidResponse
    case decoding
    case transport(String)

    var isRetryable: Bool {
        switch self {
        case .server, .transport: return true
        default: return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .badStatus(let code): return "Сервер вернул код \(code)"
        case .server(let code): return "Ошибка сервера (\(code)). Повторите позже."
        case .unauthorized: return "Сессия истекла. Войдите снова."
        case .invalidResponse: return "Некорректный ответ сервера"
        case .decoding: return "Не удалось обработать ответ сервера"
        case .transport(let message): return "Проблема сети: \(message)"
        }
    }
}
