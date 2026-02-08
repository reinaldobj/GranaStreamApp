import Foundation

/// Erros de validação de formulários
enum FormValidationError: LocalizedError {
    case invalidAmount
    case missingAccount
    case missingTransferAccount
    case sameTransferAccount
    case missingCategory
    case invalidInstallments
    case invalidDateRange
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Informe um valor válido."
        case .missingAccount:
            return "Selecione uma conta para continuar."
        case .missingTransferAccount:
            return "Selecione as contas de origem e destino."
        case .sameTransferAccount:
            return "Escolha contas diferentes para a transferência."
        case .missingCategory:
            return "Selecione uma categoria para continuar."
        case .invalidInstallments:
            return "Informe uma quantidade de parcelas válida."
        case .invalidDateRange:
            return "A data fim precisa ser maior ou igual à data de início."
        }
    }
}

// MARK: - String Extension

extension String {
    /// Retorna nil se a string estiver vazia ou contiver apenas espaços
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
