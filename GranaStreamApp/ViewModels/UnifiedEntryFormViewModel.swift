import Foundation
import SwiftUI
import Combine

/// ViewModel para gerenciar criação de transações, parcelas e recorrências
@MainActor
final class UnifiedEntryFormViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }
    
    // MARK: - Public Methods
    
    func saveSingle(
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

        if type == .transfer {
            guard !fromAccountId.isEmpty, !toAccountId.isEmpty else {
                throw FormValidationError.missingTransferAccount
            }
            guard fromAccountId != toAccountId else {
                throw FormValidationError.sameTransferAccount
            }
        } else {
            guard !accountId.isEmpty else {
                throw FormValidationError.missingAccount
            }
        }

        let request = CreateTransactionRequestDto(
            type: type,
            date: date,
            amount: amountValue,
            description: description.nilIfBlank,
            accountId: type == .transfer ? nil : accountId.nilIfBlank,
            categoryId: type == .transfer ? nil : categoryId.nilIfBlank,
            fromAccountId: type == .transfer ? fromAccountId.nilIfBlank : nil,
            toAccountId: type == .transfer ? toAccountId.nilIfBlank : nil
        )
        
        let _: CreateTransactionResponseDto = try await apiClient.request(
            "/api/v1/transactions",
            method: "POST",
            body: AnyEncodable(request)
        )
    }
    
    func saveInstallment(
        description: String,
        categoryId: String,
        accountId: String,
        totalAmount: String,
        installments: String,
        firstDueDate: Date
    ) async throws {
        guard let totalAmountValue = CurrencyTextField.value(from: totalAmount) else {
            throw FormValidationError.invalidAmount
        }
        guard let installmentsValue = Int(installments), installmentsValue > 0 else {
            throw FormValidationError.invalidInstallments
        }
        guard !categoryId.isEmpty else {
            throw FormValidationError.missingCategory
        }

        let request = CreateInstallmentSeriesRequestDto(
            description: description.nilIfBlank,
            categoryId: categoryId,
            accountDefaultId: accountId.nilIfBlank,
            totalAmount: totalAmountValue,
            installmentsPlanned: installmentsValue,
            firstDueDate: firstDueDate
        )
        
        let _: CreateInstallmentSeriesResponseDto = try await apiClient.request(
            "/api/v1/installment-series",
            method: "POST",
            body: AnyEncodable(request)
        )
    }
    
    func saveRecurring(
        type: TransactionType,
        amount: String,
        description: String,
        accountId: String,
        categoryId: String,
        frequency: RecurrenceFrequency,
        startDate: Date,
        endDate: Date?,
        hasEndDate: Bool
    ) async throws {
        guard let amountValue = CurrencyTextField.value(from: amount) else {
            throw FormValidationError.invalidAmount
        }
        guard !accountId.isEmpty else {
            throw FormValidationError.missingAccount
        }
        if let endDate, endDate < startDate {
            throw FormValidationError.invalidDateRange
        }

        let template = RecurrenceTemplateTransactionRequestDto(
            type: type,
            amount: amountValue,
            description: description.nilIfBlank,
            accountId: accountId.nilIfBlank,
            categoryId: categoryId.nilIfBlank
        )
        
        let dayOfMonth = frequency == .monthly
            ? Calendar.current.component(.day, from: startDate)
            : nil

        let request = CreateRecurrenceRequestDto(
            templateTransaction: template,
            frequency: frequency,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            dayOfMonth: dayOfMonth
        )
        
        let _: CreateRecurrenceResponseDto = try await apiClient.request(
            "/api/v1/recurrences",
            method: "POST",
            body: AnyEncodable(request)
        )
    }
}

