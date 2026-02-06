import Foundation

final class APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .custom(DateCoder.encode)
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom(DateCoder.decode)
    }

    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = [],
        body: AnyEncodable? = nil,
        requiresAuth: Bool = true,
        retryOnAuthFailure: Bool = true
    ) async throws -> T {
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
            let refreshed = await SessionStore.shared.refreshTokensIfNeeded()
            guard refreshed else {
                throw APIError.unauthorized
            }
            let token = await SessionStore.shared.getAccessToken()
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

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if http.statusCode == 401, requiresAuth, retryOnAuthFailure {
            let refreshed = await SessionStore.shared.refreshTokens()
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
            let payload = String(data: data, encoding: .utf8) ?? "<sem corpo>"
            print("Erro ao decodificar resposta em \(path): \(payload)")
            throw APIError.decodingError
        }
    }

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
