import Foundation
import Combine

@MainActor
final class ReferenceDataStore: ObservableObject {
    static let shared = ReferenceDataStore()

    @Published private(set) var accounts: [AccountResponseDto] = []
    @Published private(set) var categories: [CategoryResponseDto] = []

    func refresh() async {
        async let accountsTask: Void = loadAccounts()
        async let categoriesTask: Void = loadCategories()
        _ = await (accountsTask, categoriesTask)
    }

    func refreshAccounts() async {
        await loadAccounts()
    }

    func refreshCategories() async {
        await loadCategories()
    }

    func replaceAccounts(_ items: [AccountResponseDto]) {
        accounts = items
    }

    func replaceCategories(_ items: [CategoryResponseDto]) {
        categories = items
    }

    func loadIfNeeded() async {
        if accounts.isEmpty && categories.isEmpty {
            await refresh()
            return
        }
        if accounts.isEmpty {
            await loadAccounts()
        }
        if categories.isEmpty {
            await loadCategories()
        }
    }

    private func loadAccounts() async {
        do {
            let response: [AccountResponseDto] = try await APIClient.shared.request("/api/v1/accounts")
            accounts = response
        } catch {
            // Mantém dados atuais para evitar tela vazia quando houver falha temporária de rede.
        }
    }

    private func loadCategories() async {
        do {
            let response: [CategoryResponseDto] = try await APIClient.shared.request(
                "/api/v1/categories",
                queryItems: [
                    URLQueryItem(name: "includeHierarchy", value: "false")
                ]
            )
            categories = response
        } catch {
            // Mantém dados atuais para evitar tela vazia quando houver falha temporária de rede.
        }
    }
}
