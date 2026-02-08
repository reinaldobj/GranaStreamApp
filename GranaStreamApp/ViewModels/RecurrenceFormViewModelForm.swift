import Foundation
import SwiftUI
import Combine

/// ViewModel para RecurrenceFormView
@MainActor
final class RecurrenceFormViewModelForm: FormViewModel {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var isValid: Bool { true }
    func save() async throws { }
    
    // Delegado mantido para compatibilidade (inicializado dinamicamente na view)
    var parentViewModel: Any?
}
