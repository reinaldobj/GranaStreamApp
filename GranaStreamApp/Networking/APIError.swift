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
            return "Resposta inesperada do servidor. Veja o log no Xcode."
        }
    }
}
