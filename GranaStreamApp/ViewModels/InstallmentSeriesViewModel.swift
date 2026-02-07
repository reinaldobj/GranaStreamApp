import Foundation
import Combine // TODO: [TECH-DEBT] Import não utilizado - remover Combine

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
            errorMessage = error.userMessage
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
            errorMessage = error.userMessage
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
            errorMessage = error.userMessage
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
            errorMessage = error.userMessage
        }
    }
}
