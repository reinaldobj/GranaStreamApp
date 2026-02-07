import Foundation
import Combine // TODO: [TECH-DEBT] Import não utilizado - remover Combine

// TODO: [TECH-DEBT] Lógica de busca duplicada com CategoriesViewModel - criar protocolo SearchableViewModel
@MainActor
final class AccountsViewModel: ObservableObject {
    struct InactiveAccountInfo: Identifiable {
        let id: String
        let title: String
        let detail: String
    }

    @Published var accounts: [AccountResponseDto] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var inactiveAccount: InactiveAccountInfo?
    @Published private(set) var activeSearchTerm: String = ""

    private var allAccounts: [AccountResponseDto] = []
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol = APIClient.shared) {
        self.apiClient = apiClient
    }

    func load(syncReferenceData: Bool = false) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response: [AccountResponseDto] = try await apiClient.request("/api/v1/accounts")
            allAccounts = response
            applySearch(term: activeSearchTerm, updateActiveTerm: false)
            if syncReferenceData {
                ReferenceDataStore.shared.replaceAccounts(response)
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
        type: AccountType,
        initialBalance: Double,
        reloadAfterChange: Bool = false
    ) async -> Bool {
        do {
            inactiveAccount = nil
            let request = CreateAccountRequestDto(name: name, accountType: type, initialBalance: initialBalance)
            let response: CreateAccountResponseDto = try await apiClientt(
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
        let cleaned = term.trimmingCharacters(in: .whitespacesAndNewlines)

        if updateActiveTerm {
            activeSearchTerm = cleaned
        }

        guard !cleaned.isEmpty else {
            accounts = allAccounts
            return
        }

        let normalizedTerm = normalized(cleaned)
        accounts = allAccounts.filter { account in
            normalized(account.name ?? "").contains(normalizedTerm)
        }
    }

    private func normalized(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "pt_BR"))
            .lowercased()
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
