import Foundation
import Combine

@MainActor
final class AccountsViewModel: ObservableObject {
    @Published var accounts: [AccountResponseDto] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response: [AccountResponseDto] = try await APIClient.shared.request("/api/v1/accounts")
            accounts = response
            await ReferenceDataStore.shared.refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func create(name: String, type: AccountType, initialBalance: Double) async -> Bool {
        do {
            let request = CreateAccountRequestDto(name: name, accountType: type, initialBalance: initialBalance)
            let _: CreateAccountResponseDto = try await APIClient.shared.request(
                "/api/v1/accounts",
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
}
