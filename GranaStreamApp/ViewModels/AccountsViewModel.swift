import Foundation
import Combine

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

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response: [AccountResponseDto] = try await APIClient.shared.request("/api/v1/accounts")
            allAccounts = response
            applySearch(term: activeSearchTerm, updateActiveTerm: false)
            await ReferenceDataStore.shared.refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func applySearch(term: String) {
        applySearch(term: term, updateActiveTerm: true)
    }

    func create(name: String, type: AccountType, initialBalance: Double) async -> Bool {
        do {
            inactiveAccount = nil
            let request = CreateAccountRequestDto(name: name, accountType: type, initialBalance: initialBalance)
            let _: CreateAccountResponseDto = try await APIClient.shared.request(
                "/api/v1/accounts",
                method: "POST",
                body: AnyEncodable(request)
            )
            await load()
            return true
        } catch {
            if case APIError.server(_, let problem) = error,
               problem?.title == "Conta inativa",
               let accountId = problem?.accountId {
                let detail = problem?.detail ?? "Essa conta está desativada."
                inactiveAccount = InactiveAccountInfo(id: accountId, title: "Conta inativa", detail: detail)
                return false
            }
            errorMessage = error.localizedDescription
            return false
        }
    }

    func update(account: AccountResponseDto, name: String, type: AccountType) async -> Bool {
        do {
            let request = UpdateAccountRequestDto(name: name, accountType: type)
            try await APIClient.shared.requestNoResponse(
                "/api/v1/accounts/\(account.id)",
                method: "PATCH",
                body: AnyEncodable(request)
            )
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func delete(account: AccountResponseDto) async {
        do {
            try await APIClient.shared.requestNoResponse("/api/v1/accounts/\(account.id)", method: "DELETE")
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func reactivate(accountId: String) async -> Bool {
        do {
            try await APIClient.shared.requestNoResponse(
                "/api/v1/accounts/\(accountId)/reactivate",
                method: "PATCH"
            )
            inactiveAccount = nil
            await load()
            return true
        } catch {
            errorMessage = error.localizedDescription
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
}
