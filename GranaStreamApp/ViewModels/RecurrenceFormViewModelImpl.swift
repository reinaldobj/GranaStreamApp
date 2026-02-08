import Foundation
import SwiftUI
import Combine

/// ViewModel para RecurrenceFormView
@MainActor
final class RecurrenceFormViewModelImpl: FormViewModel {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var type: TransactionType = .expense
    @Published var amount = ""
    @Published var description = ""
    @Published var accountId: String = ""
    @Published var categoryId: String = ""
    @Published var frequency: RecurrenceFrequency = .monthly
    @Published var startDate = Date()
    @Published var endDate = Date()
    @Published var hasEndDate = false
    
    let existing: RecurrenceResponseDto?
    private let recurrencesViewModel: RecurrencesViewModel
    
    var isValid: Bool {
        guard CurrencyTextField.value(from: amount) != nil else { return false }
        guard !accountId.isEmpty else { return false }
        return true
    }
    
    init(existing: RecurrenceResponseDto?, recurrencesViewModel: RecurrencesViewModel) {
        self.existing = existing
        self.recurrencesViewModel = recurrencesViewModel
        prefill()
    }
    
    func save() async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let amountValue = CurrencyTextField.value(from: amount) else {
            throw FormValidationError.invalidAmount
        }
        
        let template = RecurrenceTemplateTransactionRequestDto(
            type: type,
            amount: amountValue,
            description: description.nilIfBlank,
            accountId: accountId.nilIfBlank,
            categoryId: categoryId.isEmpty ? nil : categoryId
        )
        
        let dayOfMonth = frequency == .monthly ? Calendar.current.component(.day, from: startDate) : nil
        
        let request = CreateRecurrenceRequestDto(
            templateTransaction: template,
            frequency: frequency,
            startDate: startDate,
            endDate: hasEndDate ? endDate : nil,
            dayOfMonth: dayOfMonth
        )
        
        let success = await recurrencesViewModel.create(request: request)
        
        guard success else {
            errorMessage = recurrencesViewModel.errorMessage ?? "Erro ao salvar recorrência"
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage ?? ""])
        }
    }
    
    private func prefill() {
        guard let existing else { return }
        type = existing.templateTransaction.type
        amount = CurrencyFormatter.string(from: existing.templateTransaction.amount)
        description = existing.templateTransaction.description ?? ""
        accountId = existing.templateTransaction.accountId ?? ""
        categoryId = existing.templateTransaction.categoryId ?? ""
        frequency = existing.frequency
        startDate = existing.startDate
        endDate = existing.endDate ?? Date()
        hasEndDate = existing.endDate != nil
    }
}
