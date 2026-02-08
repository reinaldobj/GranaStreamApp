import Foundation
import SwiftUI
import Combine

/// ViewModel para CategoryFormView
@MainActor
final class CategoryFormViewModel: FormViewModel {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var name = ""
    @Published var description = ""
    @Published var type: CategoryType = .expense
    @Published var parentId: String = ""
    @Published var sortOrder = "0"
    
    let existing: CategoryResponseDto?
    private let categoriesViewModel: CategoriesViewModel
    private let referenceStore: ReferenceDataStore
    
    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var parentOptions: [CategoryResponseDto] {
        referenceStore.categories
            .filter { $0.parentCategoryId == nil }
            .filter { $0.id != existing?.id }
            .sorted { lhs, rhs in
                if lhs.sortOrder == rhs.sortOrder {
                    return (lhs.name ?? "").localizedCaseInsensitiveCompare(rhs.name ?? "") == .orderedAscending
                }
                return lhs.sortOrder < rhs.sortOrder
            }
    }
    
    init(existing: CategoryResponseDto?, categoriesViewModel: CategoriesViewModel, referenceStore: ReferenceDataStore) {
        self.existing = existing
        self.categoriesViewModel = categoriesViewModel
        self.referenceStore = referenceStore
        prefill()
    }
    
    func save() async throws {
        isLoading = true
        defer { isLoading = false }
        
        let orderValue = Int(sortOrder) ?? 0
        let parent = parentId.isEmpty ? nil : parentId
        
        if let existing {
            let success = await categoriesViewModel.update(
                category: existing,
                name: name,
                description: description,
                type: type,
                parentId: parent,
                sortOrder: orderValue,
                reloadAfterChange: false
            )
            guard success else {
                errorMessage = categoriesViewModel.errorMessage ?? "Erro ao atualizar categoria"
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage ?? ""])
            }
        } else {
            let success = await categoriesViewModel.create(
                name: name,
                description: description,
                type: type,
                parentId: parent,
                sortOrder: orderValue,
                reloadAfterChange: false
            )
            guard success else {
                errorMessage = categoriesViewModel.errorMessage ?? "Erro ao criar categoria"
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage ?? ""])
            }
        }
    }
    
    private func prefill() {
        guard let existing else { return }
        name = existing.name ?? ""
        description = existing.description ?? ""
        type = existing.categoryType ?? .expense
        parentId = existing.parentCategoryId ?? ""
        sortOrder = String(existing.sortOrder)
    }
}
