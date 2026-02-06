import Foundation
import Combine

@MainActor
final class InstallmentSeriesViewModel: ObservableObject {
    @Published var series: [InstallmentSeriesResponseDto] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response: [InstallmentSeriesResponseDto] = try await APIClient.shared.request("/api/v1/installment-series")
            series = response
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func create(request: CreateInstallmentSeriesRequestDto) async -> Bool {
        do {
            let _: CreateInstallmentSeriesResponseDto = try await APIClient.shared.request(
                "/api/v1/installment-series",
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

    func update(id: String, request: UpdateInstallmentSeriesRequestDto) async -> Bool {
        do {
            let _: InstallmentSeriesResponseDto = try await APIClient.shared.request(
                "/api/v1/installment-series/\(id)",
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

    func delete(id: String) async {
        do {
            try await APIClient.shared.requestNoResponse(
                "/api/v1/installment-series/\(id)",
                method: "DELETE"
            )
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
