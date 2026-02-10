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
    @Published var sortOrder = 0
    @Published private(set) var parentOptions: [CategoryResponseDto] = []
    
    let existing: CategoryResponseDto?
    private let categoriesViewModel: CategoriesViewModel
    private let referenceStore: ReferenceDataStore
    private var cancellables: Set<AnyCancellable> = []

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    init(existing: CategoryResponseDto?, categoriesViewModel: CategoriesViewModel, referenceStore: ReferenceDataStore) {
        self.existing = existing
        self.categoriesViewModel = categoriesViewModel
        self.referenceStore = referenceStore
        bindCategoriesViewModel()
        bindReferenceStore()
        prefill()
        refreshParentOptions(from: bestAvailableCategories)
    }

    func loadReferenceDataIfNeeded() async {
        if !categoriesViewModel.categories.isEmpty {
            refreshParentOptions(from: categoriesViewModel.categories)
            return
        }
        await referenceStore.loadIfNeeded()
        refreshParentOptions(from: bestAvailableCategories)
    }
    
    func save() async throws {
        isLoading = true
        defer { isLoading = false }

        let parent = parentId.isEmpty ? nil : parentId

        if let existing {
            let success = await categoriesViewModel.update(
                category: existing,
                name: name,
                description: description,
                type: type,
                parentId: parent,
                sortOrder: sortOrder,
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
                sortOrder: sortOrder,
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
        sortOrder = min(max(existing.sortOrder, 0), 4)
    }

    private var bestAvailableCategories: [CategoryResponseDto] {
        let screenCategories = categoriesViewModel.categories
        if !screenCategories.isEmpty {
            return screenCategories
        }
        return referenceStore.categories
    }

    private func bindCategoriesViewModel() {
        categoriesViewModel.$loadingState
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.refreshParentOptions(from: self.bestAvailableCategories)
            }
            .store(in: &cancellables)
    }

    private func bindReferenceStore() {
        referenceStore.$categories
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                self.refreshParentOptions(from: self.bestAvailableCategories)
            }
            .store(in: &cancellables)
    }

    private func refreshParentOptions(from categories: [CategoryResponseDto]) {
        parentOptions = categories
            .filter(isParentCategory)
            .filter { $0.id != existing?.id }
            .sorted { lhs, rhs in
                if lhs.sortOrder == rhs.sortOrder {
                    return (lhs.name ?? "").localizedCaseInsensitiveCompare(rhs.name ?? "") == .orderedAscending
                }
                return lhs.sortOrder < rhs.sortOrder
            }
    }

    private func isParentCategory(_ category: CategoryResponseDto) -> Bool {
        let parentId = category.parentCategoryId?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return parentId.isEmpty
    }
}
