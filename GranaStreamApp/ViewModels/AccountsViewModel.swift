import Foundation
import SwiftUI
import Combine

@MainActor
final class AccountsViewModel: ObservableObject, SearchableViewModel {
    struct InactiveAccountInfo: Identifiable {
        let id: String
        let title: String
        let detail: String
    }

    @Published var loadingState: LoadingState<[AccountResponseDto]> = .idle
    @Published var errorMessage: String?
    @Published var inactiveAccount: InactiveAccountInfo?
    @Published private(set) var activeSearchTerm: String = ""
    
    var accounts: [AccountResponseDto] {
        if case .loaded(let items) = loadingState {
            return items
        }
        return []
    }
    
    var isLoading: Bool {
        if case .loading = loadingState {
            return true
        }
        return false
    }

    private var allAccounts: [AccountResponseDto] = []
    private let apiClient: APIClientProtocol
    private let taskManager = TaskManager()
    
    init(apiClient: APIClientProtocol? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    func load(syncReferenceData: Bool = false) async {
        taskManager.execute(id: "load") {
            self.loadingState = .loading
            do {
                let response: [AccountResponseDto] = try await self.apiClient.request("/api/v1/accounts")
                self.allAccounts = response
                self.loadingState = .loaded(response)
                self.applySearch(term: self.activeSearchTerm, updateActiveTerm: false)
                if syncReferenceData {
                    ReferenceDataStore.shared.replaceAccounts(response)
                }
                self.errorMessage = nil
            } catch {
                let message = error.userMessage ?? "Erro ao carregar contas"
                self.errorMessage = message
                self.loadingState = .error(message)
            }
        }
    }

    func applySearch(term: String) {
        applySearch(term: term, updateActiveTerm: true)
    }

    func create(
        name: String,
        type: AccountType,
        initialBalance: Double,
        reloadAfterChange: Bool = false
    ) async -> Bool {
        do {
            inactiveAccount = nil
            let request = CreateAccountRequestDto(name: name, accountType: type, initialBalance: initialBalance)
            let response: CreateAccountResponseDto = try await apiClient.request(
                "/api/v1/accounts",
                method: "POST",
                body: AnyEncodable(request)
            )

            let created = AccountResponseDto(
                id: response.id,
                name: response.name ?? name,
                initialBalance: response.initialBalance,
                accountType: type
            )
            upsertLocalAccount(created)
            ReferenceDataStore.shared.upsertAccount(created)

            if reloadAfterChange {
                await load(syncReferenceData: true)
            }
            return true
        } catch {
            if case APIError.server(_, let problem) = error,
               problem?.title == "Conta inativa",
               let accountId = problem?.accountId {
                let detail = problem?.detail ?? "Essa conta está desativada."
                inactiveAccount = InactiveAccountInfo(id: accountId, title: "Conta inativa", detail: detail)
                return false
            }
            errorMessage = error.userMessage
            return false
        }
    }

    func update(
        account: AccountResponseDto,
        name: String,
        type: AccountType,
        reloadAfterChange: Bool = false
    ) async -> Bool {
        do {
            let request = UpdateAccountRequestDto(name: name, accountType: type)
            try await apiClient.requestNoResponse(
                "/api/v1/accounts/\(account.id)",
                method: "PATCH",
                body: AnyEncodable(request)
            )

            let updated = AccountResponseDto(
                id: account.id,
                name: name,
                initialBalance: account.initialBalance,
                accountType: type
            )
            upsertLocalAccount(updated)
            ReferenceDataStore.shared.upsertAccount(updated)

            if reloadAfterChange {
                await load(syncReferenceData: true)
            }
            return true
        } catch {
            errorMessage = error.userMessage
            return false
        }
    }

    func delete(account: AccountResponseDto) async {
        do {
            try await apiClient.requestNoResponse("/api/v1/accounts/\(account.id)", method: "DELETE")
            allAccounts.removeAll { $0.id == account.id }
            applySearch(term: activeSearchTerm, updateActiveTerm: false)
            ReferenceDataStore.shared.removeAccount(id: account.id)
        } catch {
            errorMessage = error.userMessage
        }
    }

    func reactivate(accountId: String) async -> Bool {
        do {
            try await apiClient.requestNoResponse(
                "/api/v1/accounts/\(accountId)/reactivate",
                method: "PATCH"
            )
            inactiveAccount = nil
            await load(syncReferenceData: true)
            return true
        } catch {
            errorMessage = error.userMessage
            return false
        }
    }

    private func applySearch(term: String, updateActiveTerm: Bool) {
        let cleaned = SearchHelper.cleanSearchTerm(term)

        if updateActiveTerm {
            activeSearchTerm = cleaned
        }

        guard !cleaned.isEmpty else {
            loadingState = .loaded(allAccounts)
            return
        }

        let filtered = allAccounts.filter { account in
            SearchHelper.matches(account.name ?? "", searchTerm: cleaned)
        }
        loadingState = .loaded(filtered)
    }

    private func upsertLocalAccount(_ item: AccountResponseDto) {
        if let index = allAccounts.firstIndex(where: { $0.id == item.id }) {
            allAccounts[index] = item
        } else {
            allAccounts.append(item)
        }
        applySearch(term: activeSearchTerm, updateActiveTerm: false)
    }
}
