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
    private var latestLoadRequestId = UUID()
    private let taskManager = TaskManager()
    
    init(apiClient: APIClientProtocol? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    func load() async {
        let requestId = UUID()
        latestLoadRequestId = requestId

        await taskManager.executeAndWait(id: "load") {
            let previousItems = self.series
            self.isLoading = true
            self.loadingState = .loading(previousData: previousItems.isEmpty ? nil : previousItems)
            do {
                let response: [InstallmentSeriesResponseDto] = try await self.apiClient.request("/api/v1/installment-series")
                guard self.latestLoadRequestId == requestId else { return }
                self.series = response
                self.loadingState = .loaded(response)
                self.errorMessage = nil
                self.isLoading = false
            } catch {
                guard self.latestLoadRequestId == requestId else { return }
                if error.isCancellation {
                    self.isLoading = false
                    return
                }

                let message = error.userMessage ?? "Erro desconhecido"
                self.errorMessage = message
                if previousItems.isEmpty {
                    self.loadingState = .error(message)
                } else {
                    self.series = previousItems
                    self.loadingState = .loaded(previousItems)
                }
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
