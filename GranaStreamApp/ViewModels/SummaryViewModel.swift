import Foundation
import Combine

@MainActor
final class SummaryViewModel: ObservableObject {
    @Published var summary: AccountsSummaryResponseDto?
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response: AccountsSummaryResponseDto = try await APIClient.shared.request("/api/v1/accounts/summary")
            summary = response
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
