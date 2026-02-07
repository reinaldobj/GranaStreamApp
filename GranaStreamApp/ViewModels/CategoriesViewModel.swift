import Foundation
import Combine

@MainActor
final class CategoriesViewModel: ObservableObject {
    @Published var categories: [CategoryResponseDto] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var activeSearchTerm: String = ""

    private var allCategories: [CategoryResponseDto] = []

    func load(syncReferenceData: Bool = false) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response: [CategoryResponseDto] = try await APIClient.shared.request(
                "/api/v1/categories",
                queryItems: [URLQueryItem(name: "includeHierarchy", value: "false")]
            )
            allCategories = response
            applySearch(term: activeSearchTerm, updateActiveTerm: false)
            if syncReferenceData {
                ReferenceDataStore.shared.replaceCategories(response)
            }
        } catch {
            errorMessage = error.userMessage
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
            let response: CreateCategoryResponseDto = try await APIClient.shared.request(
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
            let _: CategoryResponseDto = try await APIClient.shared.request(
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
            try await APIClient.shared.requestNoResponse("/api/v1/categories/\(category.id)", method: "DELETE")
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
            let _: SeedCategoriesResponseDto = try await APIClient.shared.request(
                "/api/v1/categories/seed",
                method: "POST"
            )
            await load(syncReferenceData: true)
        } catch {
            errorMessage = error.userMessage
        }
    }

    private func applySearch(term: String, updateActiveTerm: Bool) {
        let cleaned = term.trimmingCharacters(in: .whitespacesAndNewlines)

        if updateActiveTerm {
            activeSearchTerm = cleaned
        }

        guard !cleaned.isEmpty else {
            categories = allCategories
            return
        }

        let normalizedTerm = normalized(cleaned)
        let matches = allCategories.filter { category in
            normalized(category.name ?? "").contains(normalizedTerm)
        }

        guard !matches.isEmpty else {
            categories = []
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

        categories = allCategories.filter { includedIds.contains($0.id) }
    }

    private func normalized(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "pt_BR"))
            .lowercased()
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
