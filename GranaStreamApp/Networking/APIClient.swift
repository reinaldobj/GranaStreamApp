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
    private let sessionStore: SessionStore
    
    init(sessionStore: SessionStore = .shared) {
        self.sessionStore = sessionStore
    }
    
    func refreshTokensIfNeeded() async -> Bool {
        await sessionStore.refreshTokensIfNeeded()
    }
    
    func refreshTokens() async -> Bool {
        await sessionStore.refreshTokens()
    }
    
    func getAccessToken() async -> String? {
        await sessionStore.getAccessToken()
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

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch is CancellationError {
            throw APIError.requestCancelled
        } catch let urlError as URLError {
            throw APIError.from(urlError: urlError)
        } catch {
            throw APIError.network
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

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
