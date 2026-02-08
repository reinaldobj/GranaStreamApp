import Foundation
import SwiftUI
import Combine

/// Armazena dados de referência (contas e categorias) com cache local
/// Implementa protocolos para permitir evolução independente dos domínios
@MainActor
final class ReferenceDataStore: ObservableObject, ObservableReferenceDataProvider {
    static let shared = ReferenceDataStore()

    @Published private(set) var accounts: [AccountResponseDto] = []
    @Published private(set) var categories: [CategoryResponseDto] = []

    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    // MARK: - ReferenceDataProvider

    func refresh() async {
        async let accountsTask: Void = loadAccounts()
        async let categoriesTask: Void = loadCategories()
        _ = await (accountsTask, categoriesTask)
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

    // MARK: - AccountProvider

    func refreshAccounts() async {
        await loadAccounts()
    }

    func replaceAccounts(_ items: [AccountResponseDto]) {
        accounts = items
    }

    func upsertAccount(_ item: AccountResponseDto) {
        if let index = accounts.firstIndex(where: { $0.id == item.id }) {
            accounts[index] = item
        } else {
            accounts.append(item)
        }
    }

    func removeAccount(id: String) {
        accounts.removeAll { $0.id == id }
    }

    // MARK: - CategoryProvider

    func refreshCategories() async {
        await loadCategories()
    }

    func replaceCategories(_ items: [CategoryResponseDto]) {
        categories = items
    }

    func upsertCategory(_ item: CategoryResponseDto) {
        if let index = categories.firstIndex(where: { $0.id == item.id }) {
            categories[index] = item
        } else {
            categories.append(item)
        }
    }

    func removeCategory(id: String) {
        categories.removeAll { $0.id == id }
    }

    // MARK: - Private

    private func loadAccounts() async {
        do {
            let response: [AccountResponseDto] = try await apiClient.request("/api/v1/accounts")
            accounts = response
        } catch {
            // Log do erro mas mantém dados atuais para evitar tela vazia em caso de falha de rede
            #if DEBUG
            print("⚠️ [ReferenceDataStore] Falha ao carregar contas: \(error.localizedDescription)")
            #endif
        }
    }

    private func loadCategories() async {
        do {
            let response: [CategoryResponseDto] = try await apiClient.request(
                "/api/v1/categories",
                queryItems: [
                    URLQueryItem(name: "includeHierarchy", value: "false")
                ]
            )
            categories = response
        } catch {
            // Log do erro mas mantém dados atuais para evitar tela vazia em caso de falha de rede
            #if DEBUG
            print("⚠️ [ReferenceDataStore] Falha ao carregar categorias: \(error.localizedDescription)")
            #endif
        }
    }
}
