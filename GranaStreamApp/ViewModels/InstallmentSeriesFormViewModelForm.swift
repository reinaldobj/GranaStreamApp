import Foundation
import SwiftUI
import Combine

/// ViewModel para InstallmentSeriesFormView
@MainActor
final class InstallmentSeriesFormViewModelForm: FormViewModel {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    var isValid: Bool { true }
    func save() async throws { }
    
    // Delegado para manter compatibilidade com view existente
    let parentViewModel = InstallmentSeriesViewModel()
}
