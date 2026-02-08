import Foundation
@testable import GranaStreamApp

/// Mock do APIClient para testes unitários
@MainActor
final class MockAPIClient: APIClientProtocol {
    var requestCallCount = 0
    var requestNoResponseCallCount = 0
    var lastPath: String?
    var lastMethod: String?
    var lastQueryItems: [URLQueryItem]?
    var lastBody: AnyEncodable?
    
    // Configuração de respostas
    var mockResponse: Any?
    var mockError: Error?
    var requestDelay: TimeInterval = 0
    
    // Histórico de chamadas
    var requestHistory: [(path: String, method: String)] = []
    
    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = [],
        body: AnyEncodable? = nil,
        requiresAuth: Bool = true,
        retryOnAuthFailure: Bool = true
    ) async throws -> T {
        requestCallCount += 1
        lastPath = path
        lastMethod = method
        lastQueryItems = queryItems
        lastBody = body
        requestHistory.append((path: path, method: method))
        
        if requestDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }
        
        if let error = mockError {
            throw error
        }
        
        guard let response = mockResponse as? T else {
            throw APIError.decodingError
        }
        
        return response
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
        // Para testes, usar same behavior que request()
        // (não fazer retry de verdade para evitar delays nos testes)
        try await request(
            path,
            method: method,
            queryItems: queryItems,
            body: body,
            requiresAuth: requiresAuth,
            retryOnAuthFailure: retryOnAuthFailure
        )
    }
    
    func requestNoResponse(
        _ path: String,
        method: String,
        queryItems: [URLQueryItem] = [],
        body: AnyEncodable? = nil,
        requiresAuth: Bool = true
    ) async throws {
        requestNoResponseCallCount += 1
        lastPath = path
        lastMethod = method
        lastQueryItems = queryItems
        lastBody = body
        requestHistory.append((path: path, method: method))
        
        if requestDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }
        
        if let error = mockError {
            throw error
        }
    }
    
    func reset() {
        requestCallCount = 0
        requestNoResponseCallCount = 0
        lastPath = nil
        lastMethod = nil
        lastQueryItems = nil
        lastBody = nil
        mockResponse = nil
        mockError = nil
        requestDelay = 0
        requestHistory.removeAll()
    }
}
