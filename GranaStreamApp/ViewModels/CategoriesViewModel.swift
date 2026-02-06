import Foundation
import Combine

@MainActor
final class CategoriesViewModel: ObservableObject {
    @Published var categories: [CategoryResponseDto] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response: [CategoryResponseDto] = try await APIClient.shared.request(
                "/api/v1/categories",
                queryItems: [URLQueryItem(name: "includeHierarchy", value: "false")]
            )
            categories = response
            await ReferenceDataStore.shared.refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func create(name: String, description: String, type: CategoryType, parentId: String?, sortOrder: Int) async -> Bool {
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
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func update(category: CategoryResponseDto, name: String, description: String, type: CategoryType, parentId: String?, sortOrder: Int) async -> Bool {
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
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func delete(category: CategoryResponseDto) async {
        do {
            try await APIClient.shared.requestNoResponse("/api/v1/categories/\(category.id)", method: "DELETE")
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func seed() async {
        do {
            let _: SeedCategoriesResponseDto = try await APIClient.shared.request(
                "/api/v1/categories/seed",
                method: "POST"
            )
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
