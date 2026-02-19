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
    var mockResponsesByPath: [String: Any] = [:]
    var mockResponsesByPathAndMethod: [String: Any] = [:]
    var mockResponseQueueByPath: [String: [Any]] = [:]
    var mockErrorsByPath: [String: Error] = [:]
    var mockErrorsByPathAndMethod: [String: Error] = [:]
    var mockErrorQueueByPath: [String: [Error]] = [:]
    var requestDelay: TimeInterval = 0
    
    // Histórico de chamadas
    var requestHistory: [(path: String, method: String)] = []
    var requestHistoryDetailed: [(path: String, method: String, queryItems: [URLQueryItem])] = []
    
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
        requestHistoryDetailed.append((path: path, method: method, queryItems: queryItems))
        
        if requestDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }

        if let error = consumeError(path: path, method: method) {
            throw error
        }

        guard let response = consumeResponse(path: path, method: method) as? T else {
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
        requestHistoryDetailed.append((path: path, method: method, queryItems: queryItems))
        
        if requestDelay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(requestDelay * 1_000_000_000))
        }

        if let error = consumeError(path: path, method: method) {
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
        mockResponsesByPath = [:]
        mockResponsesByPathAndMethod = [:]
        mockResponseQueueByPath = [:]
        mockErrorsByPath = [:]
        mockErrorsByPathAndMethod = [:]
        mockErrorQueueByPath = [:]
        requestDelay = 0
        requestHistory.removeAll()
        requestHistoryDetailed.removeAll()
    }

    private func consumeResponse(path: String, method: String) -> Any? {
        if var queue = mockResponseQueueByPath[path], !queue.isEmpty {
            let first = queue.removeFirst()
            mockResponseQueueByPath[path] = queue
            return first
        }

        let key = pathAndMethodKey(path: path, method: method)
        if let response = mockResponsesByPathAndMethod[key] {
            return response
        }
        if let response = mockResponsesByPath[path] {
            return response
        }
        return mockResponse
    }

    private func consumeError(path: String, method: String) -> Error? {
        if var queue = mockErrorQueueByPath[path], !queue.isEmpty {
            let first = queue.removeFirst()
            mockErrorQueueByPath[path] = queue
            return first
        }

        let key = pathAndMethodKey(path: path, method: method)
        if let error = mockErrorsByPathAndMethod[key] {
            return error
        }
        if let error = mockErrorsByPath[path] {
            return error
        }
        return mockError
    }

    private func pathAndMethodKey(path: String, method: String) -> String {
        "\(method.uppercased()) \(path)"
    }
}
