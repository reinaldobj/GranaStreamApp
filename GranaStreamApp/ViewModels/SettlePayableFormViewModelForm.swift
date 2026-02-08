import Foundation
import SwiftUI
import Combine

/// ViewModel para SettlePayableFormView
@MainActor
final class SettlePayableFormViewModelForm: FormViewModel {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var isValid: Bool { true }
    func save() async throws { }
    
    // Delegado para manter compatibilidade
    let parentViewModel = PayablesViewModel()
}
