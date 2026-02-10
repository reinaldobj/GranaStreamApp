import Foundation

/// Protocolo para gerenciar autenticação - permite injetar diferentes implementações
@MainActor
protocol AuthenticationProvider: AnyObject {
    func refreshTokensIfNeeded() async -> Bool
    func refreshTokens() async -> Bool
    func getAccessToken() async -> String?
}

/// Implementação padrão usando SessionStore
final class SessionStoreAuthenticationProvider: AuthenticationProvider {
    func refreshTokensIfNeeded() async -> Bool {
        await SessionStore.shared.refreshTokensIfNeeded()
    }

    func refreshTokens() async -> Bool {
        await SessionStore.shared.refreshTokens()
    }

    func getAccessToken() async -> String? {
        await SessionStore.shared.getAccessToken()
    }
}

/// Cliente API com injeção de dependência completa
final class APIClient: APIClientProtocol {
    static let shared = APIClient()

    private let session: URLSession
    private let authenticationProvider: AuthenticationProvider

    init(
        session: URLSession = .shared,
        authenticationProvider: AuthenticationProvider? = nil
    ) {
        self.session = session
        self.authenticationProvider = authenticationProvider ?? SessionStoreAuthenticationProvider()
    }

    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = [],
        body: AnyEncodable? = nil,
        requiresAuth: Bool = true,
        retryOnAuthFailure: Bool = true
    ) async throws -> T {
        let encoder = makeEncoder()
        let decoder = makeDecoder()

        var url = AppConfig.baseURL
        url.append(path: path)
        if !queryItems.isEmpty {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = queryItems
            if let updated = components?.url {
                url = updated
            }
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        if requiresAuth {
            let refreshed = await authenticationProvider.refreshTokensIfNeeded()
            guard refreshed else {
                throw APIError.unauthorized
            }
            let token = await authenticationProvider.getAccessToken()
            if let token {
                urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
        }

        if ["POST", "PUT", "PATCH"].contains(method.uppercased()) {
            let key = UUID().uuidString.replacingOccurrences(of: "-", with: "")
            urlRequest.setValue(key, forHTTPHeaderField: "Idempotency-Key")
        }

        if let body {
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.httpBody = try encoder.encode(body)
        }

        let startTime = Date()
        #if DEBUG
        if AppConfig.enableNetworkLogging, shouldLogRequest(path: path, method: method) {
            logRequest(urlRequest, path: path)
        }
        #endif

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch is CancellationError {
            throw APIError.requestCancelled
        } catch let urlError as URLError {
            #if DEBUG
            if AppConfig.enableNetworkLogging, shouldLogRequest(path: path, method: method) {
                logNetworkError(urlError, path: path)
            }
            #endif
            throw APIError.from(urlError: urlError)
        } catch {
            #if DEBUG
            if AppConfig.enableNetworkLogging, shouldLogRequest(path: path, method: method) {
                logUnexpectedError(error, path: path)
            }
            #endif
            throw APIError.network
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        #if DEBUG
        if AppConfig.enableNetworkLogging, shouldLogRequest(path: path, method: method) {
            let duration = Date().timeIntervalSince(startTime)
            logResponse(http, data: data, duration: duration, path: path)
        }
        #endif

        if http.statusCode == 401, requiresAuth, retryOnAuthFailure {
            let refreshed = await authenticationProvider.refreshTokens()
            if refreshed {
                return try await self.request(
                    path,
                    method: method,
                    queryItems: queryItems,
                    body: body,
                    requiresAuth: requiresAuth,
                    retryOnAuthFailure: false
                )
            }
            throw APIError.unauthorized
        }

        if http.statusCode == 408 || http.statusCode == 504 {
            throw APIError.timeout
        }

        guard (200...299).contains(http.statusCode) else {
            let problem = try? decoder.decode(ProblemDetails.self, from: data)
            throw APIError.server(status: http.statusCode, problem: problem)
        }

        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            #if DEBUG
            print("Falha ao processar a resposta da rota \(path). Status HTTP: \(http.statusCode).")
            #endif
            throw APIError.decodingError
        }
    }

    // MARK: - Private

    private func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom(DateCoder.encode)
        return encoder
    }

    private func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom(DateCoder.decode)
        return decoder
    }

    #if DEBUG
    private func shouldLogRequest(path: String, method: String) -> Bool {
        let normalizedPath = path.lowercased()
        let normalizedMethod = method.uppercased()
        if normalizedPath == "/api/v1/budgets" {
            return ["PUT", "POST", "PATCH"].contains(normalizedMethod)
        }
        return false
    }

    private func logRequest(_ request: URLRequest, path: String) {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? path
        let headers = sanitizedHeaders(request.allHTTPHeaderFields)
        print("➡️ [API] \(method) \(url)")
        if !headers.isEmpty {
            print("➡️ [API] headers: \(headers)")
        }
        if let bodyData = request.httpBody, let bodyText = String(data: bodyData, encoding: .utf8) {
            let trimmed = truncate(bodyText)
            print("➡️ [API] body: \(trimmed)")
        }
    }

    private func logResponse(_ response: HTTPURLResponse, data: Data, duration: TimeInterval, path: String) {
        let url = response.url?.absoluteString ?? path
        let durationText = String(format: "%.2f", duration)
        print("⬅️ [API] \(response.statusCode) \(url) (\(durationText)s)")
        if let bodyText = String(data: data, encoding: .utf8), !bodyText.isEmpty {
            let trimmed = truncate(bodyText)
            print("⬅️ [API] body: \(trimmed)")
        }
    }

    private func logNetworkError(_ error: URLError, path: String) {
        print("❌ [API] Network error on \(path): \(error.code.rawValue) \(error.localizedDescription)")
    }

    private func logUnexpectedError(_ error: Error, path: String) {
        print("❌ [API] Unexpected error on \(path): \(error.localizedDescription)")
    }

    private func sanitizedHeaders(_ headers: [String: String]?) -> [String: String] {
        guard let headers else { return [:] }
        var sanitized: [String: String] = [:]
        for (key, value) in headers {
            if key.lowercased() == "authorization" {
                sanitized[key] = "Bearer ***"
            } else {
                sanitized[key] = value
            }
        }
        return sanitized
    }

    private func truncate(_ text: String, maxLength: Int = 4000) -> String {
        if text.count <= maxLength {
            return text
        }
        let index = text.index(text.startIndex, offsetBy: maxLength)
        return String(text[..<index]) + "…"
    }
    #endif

    // MARK: - Retry Logic

    /// Executa uma requisição com retry automático para erros de rede
    /// Usa exponential backoff: 1s, 2s, 4s para 3 tentativas
    func requestWithRetry<T: Decodable>(
        _ path: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = [],
        body: AnyEncodable? = nil,
        requiresAuth: Bool = true,
        retryOnAuthFailure: Bool = true,
        maxRetries: Int = 3
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await request(
                    path,
                    method: method,
                    queryItems: queryItems,
                    body: body,
                    requiresAuth: requiresAuth,
                    retryOnAuthFailure: retryOnAuthFailure
                )
            } catch let error as APIError where error.isRetryable {
                lastError = error
                
                // Não fazer retry na última tentativa
                if attempt < maxRetries - 1 {
                    // Exponential backoff: 1s, 2s, 4s
                    let delaySeconds = pow(2.0, Double(attempt))
                    let delayNanoseconds = UInt64(delaySeconds * 1_000_000_000)
                    
                    #if DEBUG
                    print("⚠️ [APIClient] Erro retentável (\(error.localizedDescription)). Tentativa \(attempt + 1)/\(maxRetries). Aguardando \(delaySeconds)s...")
                    #endif
                    
                    try await Task.sleep(nanoseconds: delayNanoseconds)
                } else {
                    #if DEBUG
                    print("❌ [APIClient] Erro após \(maxRetries) tentativas: \(error.localizedDescription)")
                    #endif
                }
            } catch {
                // Erros não-retentáveis são lançados imediatamente
                throw error
            }
        }
        
        // Lançar o último erro ou erro genérico se não houver último erro
        throw lastError ?? APIError.network
    }

    // MARK: - Request Methods

    func requestNoResponse(
        _ path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: AnyEncodable? = nil,
        requiresAuth: Bool = true
    ) async throws {
        let _: EmptyResponse = try await request(
            path,
            method: method,
            queryItems: queryItems,
            body: body,
            requiresAuth: requiresAuth
        )
    }
}

struct EmptyResponse: Codable {}
