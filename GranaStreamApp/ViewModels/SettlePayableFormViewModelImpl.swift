import Foundation
import SwiftUI
import Combine

/// ViewModel para SettlePayableFormView
@MainActor
final class SettlePayableFormViewModelImpl: FormViewModel {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var accountId: String
    @Published var categoryId: String
    @Published var paidDate: Date
    
    let payable: PayableListItemDto
    let actionTitle: String
    let transactionType: TransactionType
    let onConfirm: (SettlePayableRequestDto) async -> Bool
    
    var isValid: Bool {
        !accountId.isEmpty
    }
    
    init(
        payable: PayableListItemDto,
        actionTitle: String,
        transactionType: TransactionType,
        onConfirm: @escaping (SettlePayableRequestDto) async -> Bool
    ) {
        self.payable = payable
        self.actionTitle = actionTitle
        self.transactionType = transactionType
        self.onConfirm = onConfirm
        self.accountId = payable.accountId ?? ""
        self.categoryId = payable.categoryId ?? ""
        self.paidDate = payable.dueDate
    }
    
    func save() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let request = SettlePayableRequestDto(
            accountId: accountId,
            categoryId: categoryId.isEmpty ? "" : categoryId,
            paidDate: paidDate
        )
        
        let success = await onConfirm(request)
        guard success else {
            errorMessage = "Erro ao confirmar pagamento"
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage ?? ""])
        }
    }
}
