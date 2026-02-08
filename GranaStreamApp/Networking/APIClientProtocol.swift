import Foundation

/// Protocolo para permitir mock do APIClient em testes
protocol APIClientProtocol {
    func request<T: Decodable>(
        _ path: String,
        method: String,
        queryItems: [URLQueryItem],
        body: AnyEncodable?,
        requiresAuth: Bool,
        retryOnAuthFailure: Bool
    ) async throws -> T
    
    func requestWithRetry<T: Decodable>(
        _ path: String,
        method: String,
        queryItems: [URLQueryItem],
        body: AnyEncodable?,
        requiresAuth: Bool,
        retryOnAuthFailure: Bool,
        maxRetries: Int
    ) async throws -> T
    
    func requestNoResponse(
        _ path: String,
        method: String,
        queryItems: [URLQueryItem],
        body: AnyEncodable?,
        requiresAuth: Bool
    ) async throws
}

// Extension para valores padrão (mantém API existente)
extension APIClientProtocol {
    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = [],
        body: AnyEncodable? = nil,
        requiresAuth: Bool = true,
        retryOnAuthFailure: Bool = true
    ) async throws -> T {
        try await request(
            path,
            method: method,
            queryItems: queryItems,
            body: body,
            requiresAuth: requiresAuth,
            retryOnAuthFailure: retryOnAuthFailure
        )
    }
    
    func requestWithRetry<T: Decodable>(
        _ path: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = [],
        body: AnyEncodable? = nil,
        requiresAuth: Bool = true,
        retryOnAuthFailure: Bool = true,
        maxRetries: Int = 3
    ) async throws -> T {
        try await requestWithRetry(
            path,
            method: method,
            queryItems: queryItems,
            body: body,
            requiresAuth: requiresAuth,
            retryOnAuthFailure: retryOnAuthFailure,
            maxRetries: maxRetries
        )
    }
    
    func requestNoResponse(
        _ path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: AnyEncodable? = nil,
        requiresAuth: Bool = true
    ) async throws {
        try await requestNoResponse(
            path,
            method: method,
            queryItems: queryItems,
            body: body,
            requiresAuth: requiresAuth
        )
    }
}
