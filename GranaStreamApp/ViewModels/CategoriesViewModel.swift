import Foundation
import SwiftUI
import Combine

@MainActor
final class CategoriesViewModel: ObservableObject, SearchableViewModel {
    @Published var loadingState: LoadingState<[CategoryResponseDto]> = .idle
    @Published var errorMessage: String?
    @Published private(set) var activeSearchTerm: String = ""
    
    var categories: [CategoryResponseDto] {
        loadingState.data ?? []
    }
    
    var isLoading: Bool {
        if case .loading = loadingState {
            return true
        }
        return false
    }

    private var allCategories: [CategoryResponseDto] = []
    private var latestLoadRequestId = UUID()
    private let apiClient: APIClientProtocol
    private let taskManager = TaskManager()
    
    init(apiClient: APIClientProtocol? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    func load(syncReferenceData: Bool = false) async {
        let requestId = UUID()
        latestLoadRequestId = requestId

        await taskManager.executeAndWait(id: "load") {
            let previousItems = self.categories
            self.loadingState = .loading(previousData: previousItems.isEmpty ? nil : previousItems)
            do {
                let response: [CategoryResponseDto] = try await self.apiClient.request(
                    "/api/v1/categories",
                    queryItems: [URLQueryItem(name: "includeHierarchy", value: "false")]
                )
                guard self.latestLoadRequestId == requestId else { return }

                self.allCategories = response
                self.loadingState = .loaded(response)
                self.applySearch(term: self.activeSearchTerm, updateActiveTerm: false)
                if syncReferenceData {
                    ReferenceDataStore.shared.replaceCategories(response)
                }
                self.errorMessage = nil
            } catch {
                guard self.latestLoadRequestId == requestId else { return }
                if error.isCancellation {
                    return
                }

                let message = error.userMessage ?? "Erro ao carregar categorias"
                self.errorMessage = message
                if previousItems.isEmpty {
                    self.loadingState = .error(message)
                } else {
                    self.loadingState = .loaded(previousItems)
                }
            }
        }
    }

    func applySearch(term: String) {
        applySearch(term: term, updateActiveTerm: true)
    }

    func create(
        name: String,
        description: String,
        type: CategoryType,
        parentId: String?,
        sortOrder: Int,
        reloadAfterChange: Bool = false
    ) async -> Bool {
        do {
            let request = CreateCategoryRequestDto(
                name: name,
                description: description,
                categoryType: type,
                parentCategoryId: parentId,
                sortOrder: sortOrder
            )
            let response: CreateCategoryResponseDto = try await apiClient.request(
                "/api/v1/categories",
                method: "POST",
                body: AnyEncodable(request)
            )

            let created = CategoryResponseDto(
                id: response.id,
                name: response.name ?? name,
                description: response.description ?? description,
                categoryType: response.categoryType ?? type,
                parentCategoryId: response.parentCategoryId,
                parentCategoryName: response.parentCategoryName,
                sortOrder: response.sortOrder,
                isActive: true,
                subCategories: nil
            )
            upsertLocalCategory(created)
            ReferenceDataStore.shared.upsertCategory(created)

            if reloadAfterChange {
                await load(syncReferenceData: true)
            }
            return true
        } catch {
            errorMessage = error.userMessage
            return false
        }
    }

    func update(
        category: CategoryResponseDto,
        name: String,
        description: String,
        type: CategoryType,
        parentId: String?,
        sortOrder: Int,
        reloadAfterChange: Bool = false
    ) async -> Bool {
        do {
            let request = UpdateCategoryRequestDto(
                name: name,
                description: description,
                categoryType: type,
                parentCategoryId: parentId,
                sortOrder: sortOrder
            )
            let _: CategoryResponseDto = try await apiClient.request(
                "/api/v1/categories/\(category.id)",
                method: "PUT",
                body: AnyEncodable(request)
            )

            let updated = CategoryResponseDto(
                id: category.id,
                name: name,
                description: description,
                categoryType: type,
                parentCategoryId: parentId,
                parentCategoryName: category.parentCategoryName,
                sortOrder: sortOrder,
                isActive: category.isActive,
                subCategories: category.subCategories
            )
            upsertLocalCategory(updated)
            ReferenceDataStore.shared.upsertCategory(updated)

            if reloadAfterChange {
                await load(syncReferenceData: true)
            }
            return true
        } catch {
            errorMessage = error.userMessage
            return false
        }
    }

    func delete(category: CategoryResponseDto) async {
        do {
            try await apiClient.requestNoResponse("/api/v1/categories/\(category.id)", method: "DELETE")
            let removedIds = categoriesToRemove(for: category.id)
            allCategories.removeAll { removedIds.contains($0.id) }
            applySearch(term: activeSearchTerm, updateActiveTerm: false)
            for id in removedIds {
                ReferenceDataStore.shared.removeCategory(id: id)
            }
        } catch {
            errorMessage = error.userMessage
        }
    }

    func seed() async {
        do {
            let _: SeedCategoriesResponseDto = try await apiClient.request(
                "/api/v1/categories/seed",
                method: "POST"
            )
            await load(syncReferenceData: true)
        } catch {
            errorMessage = error.userMessage
        }
    }

    private func applySearch(term: String, updateActiveTerm: Bool) {
        let cleaned = SearchHelper.cleanSearchTerm(term)

        if updateActiveTerm {
            activeSearchTerm = cleaned
        }

        guard !cleaned.isEmpty else {
            loadingState = .loaded(allCategories)
            return
        }

        let matches = allCategories.filter { category in
            SearchHelper.matches(category.name ?? "", searchTerm: cleaned)
        }

        guard !matches.isEmpty else {
            loadingState = .loaded([])
            return
        }

        var includedIds = Set(matches.map(\.id))
        let matchedParentIds = Set(matches.filter { $0.parentCategoryId == nil }.map(\.id))

        for category in matches {
            if let parentId = category.parentCategoryId {
                includedIds.insert(parentId)
            }
        }

        if !matchedParentIds.isEmpty {
            for category in allCategories where category.parentCategoryId != nil {
                if let parentId = category.parentCategoryId, matchedParentIds.contains(parentId) {
                    includedIds.insert(category.id)
                }
            }
        }

        let filtered = allCategories.filter { includedIds.contains($0.id) }
        loadingState = .loaded(filtered)
    }

    private func upsertLocalCategory(_ item: CategoryResponseDto) {
        if let index = allCategories.firstIndex(where: { $0.id == item.id }) {
            allCategories[index] = item
        } else {
            allCategories.append(item)
        }
        applySearch(term: activeSearchTerm, updateActiveTerm: false)
    }

    private func categoriesToRemove(for rootId: String) -> Set<String> {
        var removedIds: Set<String> = [rootId]
        var changed = true

        while changed {
            changed = false
            for category in allCategories {
                if let parentId = category.parentCategoryId, removedIds.contains(parentId), !removedIds.contains(category.id) {
                    removedIds.insert(category.id)
                    changed = true
                }
            }
        }

        return removedIds
    }
}
