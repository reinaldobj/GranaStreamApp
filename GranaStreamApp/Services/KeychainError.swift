import Foundation
import Security

/// Erros de operações Keychain
enum KeychainError: LocalizedError, CustomDebugStringConvertible {
    case saveFailed(OSStatus)
    case retrievalFailed(OSStatus)
    case deletionFailed(OSStatus)
    case decodingFailed
    case invalidInput
    
    // MARK: - LocalizedError
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Falha ao salvar no Keychain (status: \(status))"
        case .retrievalFailed(let status):
            return "Falha ao recuperar do Keychain (status: \(status))"
        case .deletionFailed(let status):
            return "Falha ao deletar do Keychain (status: \(status))"
        case .decodingFailed:
            return "Falha ao decodificar dados do Keychain"
        case .invalidInput:
            return "Entrada inválida para operação Keychain"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .saveFailed(let status):
            return keychainErrorDescription(status)
        case .retrievalFailed(let status):
            return keychainErrorDescription(status)
        case .deletionFailed(let status):
            return keychainErrorDescription(status)
        case .decodingFailed:
            return "Os dados recuperados não podem ser interpretados como UTF-8"
        case .invalidInput:
            return "Chave ou valor vazios/inválidos"
        }
    }
    
    var debugDescription: String {
        let error = errorDescription ?? "Erro desconhecido"
        let reason = failureReason ?? "Sem detalhes adicionais"
        return "\(error): \(reason)"
    }
    
    // MARK: - Helpers
    
    private func keychainErrorDescription(_ status: OSStatus) -> String {
        switch status {
        case errSecSuccess:
            return "Operação bem-sucedida"
        case errSecUnimplemented:
            return "Função não implementada"
        case errSecIO:
            return "Erro de I/O"
        case errSecOpWr:
            return "Falha ao escrever"
        case errSecParam:
            return "Parâmetro inválido"
        case errSecAllocate:
            return "Falha ao alocar memória"
        case errSecUserCanceled:
            return "Operação cancelada pelo usuário"
        case errSecBadReq:
            return "Requisição inválida"
        case errSecItemNotFound:
            return "Item não encontrado"
        case errSecInteractionNotAllowed:
            return "Interação não permitida"
        case errSecDuplicateItem:
            return "Item duplicado"
        default:
            return "Erro Keychain desconhecido (código: \(status))"
        }
    }
}
