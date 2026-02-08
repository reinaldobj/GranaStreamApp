import Foundation
import SwiftUI
import Combine

/// ViewModel para gerenciar criação e edição de transações
/// Implementa FormViewModel para integração com FormViewContainer
@MainActor
final class TransactionFormViewModel: FormViewModel {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var isValid: Bool {
        true  // Validação delegada para a View por enquanto
    }
    
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }
    
    func save() async throws {
        // Implementação vazia - metodos específicos são chamados diretamente
    }
    
    func createTransaction(
        type: TransactionType,
        date: Date,
        amount: String,
        description: String,
        accountId: String,
        categoryId: String,
        fromAccountId: String,
        toAccountId: String
    ) async throws {
        guard let amountValue = CurrencyTextField.value(from: amount) else {
            throw FormValidationError.invalidAmount
        }

        let request = CreateTransactionRequestDto(
            type: type,
            date: date,
            amount: amountValue,
            description: description.isEmpty ? nil : description,
            accountId: type == .transfer ? nil : (accountId.isEmpty ? nil : accountId),
            categoryId: type == .transfer ? nil : (categoryId.isEmpty ? nil : categoryId),
            fromAccountId: type == .transfer ? (fromAccountId.isEmpty ? nil : fromAccountId) : nil,
            toAccountId: type == .transfer ? (toAccountId.isEmpty ? nil : toAccountId) : nil
        )
        
        let _: CreateTransactionResponseDto = try await apiClient.request(
            "/api/v1/transactions",
            method: "POST",
            body: AnyEncodable(request)
        )
    }
    
    func updateTransaction(
        id: String,
        amount: String,
        date: Date,
        description: String,
        categoryId: String,
        fromAccountId: String,
        toAccountId: String
    ) async throws {
        guard let amountValue = CurrencyTextField.value(from: amount) else {
            throw FormValidationError.invalidAmount
        }

        let request = UpdateTransactionRequestDto(
            amount: amountValue,
            date: date,
            description: description.isEmpty ? nil : description,
            categoryId: categoryId.isEmpty ? nil : categoryId,
            fromAccountId: fromAccountId.isEmpty ? nil : fromAccountId,
            toAccountId: toAccountId.isEmpty ? nil : toAccountId
        )
        
        let _: TransactionResponseDto = try await apiClient.request(
            "/api/v1/transactions/\(id)",
            method: "PATCH",
            body: AnyEncodable(request)
        )
    }
}
