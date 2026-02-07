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
        reloadAfterChange: Bool = true
    ) async -> Bool {
        do {
            let request = CreateCategoryRequestDto(
                name: name,
                description: description,
                categoryType: type,
                parentCategoryId: parentId,
                sortOrder: sortOrder
            )
            let _: CreateCategoryResponseDto = try await APIClient.shared.request(
                "/api/v1/categories",
                method: "POST",
                body: AnyEncodable(request)
            )
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
        reloadAfterChange: Bool = true
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
            await load(syncReferenceData: true)
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
}
