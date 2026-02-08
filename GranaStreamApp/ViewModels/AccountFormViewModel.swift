import Foundation
import SwiftUI
import Combine

/// ViewModel para AccountFormView
@MainActor
final class AccountFormViewModel: FormViewModel {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var name = ""
    @Published var type: AccountType = .contaCorrente
    @Published var initialBalance = ""
    
    let existing: AccountResponseDto?
    private let accountsViewModel: AccountsViewModel
    
    var isValid: Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if existing == nil {
            return !trimmedName.isEmpty && CurrencyTextFieldHelper.value(from: initialBalance) != nil
        }
        return !trimmedName.isEmpty
    }
    
    init(existing: AccountResponseDto?, accountsViewModel: AccountsViewModel) {
        self.existing = existing
        self.accountsViewModel = accountsViewModel
        prefill()
    }
    
    func save() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let balanceValue = CurrencyTextFieldHelper.value(from: initialBalance) ?? 0
        
        if let existing {
            let success = await accountsViewModel.update(
                account: existing,
                name: trimmedName,
                type: type,
                reloadAfterChange: false
            )
            guard success else {
                errorMessage = accountsViewModel.errorMessage ?? "Erro ao atualizar conta"
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage ?? ""])
            }
        } else {
            let success = await accountsViewModel.create(
                name: trimmedName,
                type: type,
                initialBalance: balanceValue,
                reloadAfterChange: false
            )
            guard success else {
                errorMessage = accountsViewModel.errorMessage ?? "Erro ao criar conta"
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage ?? ""])
            }
        }
    }
    
    private func prefill() {
        guard let existing else {
            name = ""
            type = .contaCorrente
            initialBalance = ""
            return
        }
        name = existing.name ?? ""
        type = existing.accountType
    }
}
