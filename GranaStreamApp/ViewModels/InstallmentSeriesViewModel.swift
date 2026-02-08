import Foundation
import SwiftUI
import Combine

@MainActor
final class InstallmentSeriesViewModel: ObservableObject {
    @Published var series: [InstallmentSeriesResponseDto] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var loadingState: LoadingState<[InstallmentSeriesResponseDto]> = .idle

    private let apiClient: APIClientProtocol
    private let taskManager = TaskManager()
    
    init(apiClient: APIClientProtocol? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    func load() async {
        taskManager.execute(id: "load") {
            self.loadingState = .loading
            do {
                let response: [InstallmentSeriesResponseDto] = try await self.apiClient.request("/api/v1/installment-series")
                self.series = response
                self.loadingState = .loaded(response)
                self.isLoading = false
            } catch {
                self.errorMessage = error.userMessage
                self.loadingState = .error(error.userMessage ?? "Erro desconhecido")
                self.isLoading = false
            }
        }
    }

    func create(request: CreateInstallmentSeriesRequestDto) async -> Bool {
        do {
            let _: CreateInstallmentSeriesResponseDto = try await apiClient.request(
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
            let _: InstallmentSeriesResponseDto = try await apiClient.request(
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
            try await apiClient.requestNoResponse(
                "/api/v1/installment-series/\(id)",
                method: "DELETE"
            )
            await load()
        } catch {
            errorMessage = error.userMessage
        }
    }
}
