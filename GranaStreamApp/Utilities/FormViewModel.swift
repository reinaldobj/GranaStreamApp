import Foundation
import Combine

/// Protocolo que define o contrato para ViewModels de formulários
/// Garante consistência entre todos os formulários e facilita componentização
protocol FormViewModel: AnyObject, ObservableObject {
    /// Indica se a operação de salvar está em progresso
    var isLoading: Bool { get }
    
    /// Mensagem de erro (nil se sem erro)
    var errorMessage: String? { get set }
    
    /// Indica se o formulário está válido para envio
    var isValid: Bool { get }
    
    /// Executa a lógica de salvar do formulário
    /// - Throws: Erro se a operação falhar
    func save() async throws
    
    /// Limpa mensagens de erro
    func clearError()
}

// MARK: - Default Implementation

extension FormViewModel {
    /// Implementação padrão de clearError
    func clearError() {
        errorMessage = nil
    }
}
