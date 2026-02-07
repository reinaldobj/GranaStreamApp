import Foundation

struct ProblemDetails: Codable {
    let type: String?
    let title: String?
    let status: Int?
    let detail: String?
    let instance: String?
    let errors: [String: [String]]?
    let accountId: String?
}

enum APIError: Error, LocalizedError {
    case invalidResponse
    case server(status: Int, problem: ProblemDetails?)
    case unauthorized
    case decodingError
    case timeout
    case offline
    case requestCancelled
    case network

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Resposta inválida do servidor."
        case .server(_, let problem):
            if let errors = problem?.errors, !errors.isEmpty {
                let messages = errors.values.flatMap { $0 }
                if !messages.isEmpty {
                    return messages.joined(separator: "\n")
                }
            }
            return problem?.detail ?? problem?.title ?? "Erro no servidor."
        case .unauthorized:
            return "Sessão expirada. Faça login novamente."
        case .decodingError:
            return "Não foi possível entender a resposta do servidor."
        case .timeout:
            return "A conexão demorou demais. Tente novamente."
        case .offline:
            return "Você está sem internet. Verifique sua conexão."
        case .requestCancelled:
            return "A solicitação foi cancelada."
        case .network:
            return "Não foi possível conectar ao servidor. Tente novamente."
        }
    }

    static func from(urlError: URLError) -> APIError {
        switch urlError.code {
        case .timedOut:
            return .timeout
        case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost, .dnsLookupFailed:
            return .offline
        case .cancelled:
            return .requestCancelled
        default:
            return .network
        }
    }
}
