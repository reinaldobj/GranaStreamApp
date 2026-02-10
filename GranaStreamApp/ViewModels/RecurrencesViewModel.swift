import Foundation
import SwiftUI
import Combine

@MainActor
final class RecurrencesViewModel: ObservableObject {
    @Published var recurrences: [RecurrenceResponseDto] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var loadingState: LoadingState<[RecurrenceResponseDto]> = .idle

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
            let previousItems = self.recurrences
            self.isLoading = true
            self.loadingState = .loading(previousData: previousItems.isEmpty ? nil : previousItems)
            do {
                let response: [RecurrenceResponseDto] = try await self.apiClient.request("/api/v1/recurrences")
                guard self.latestLoadRequestId == requestId else { return }
                self.recurrences = response
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
                    self.recurrences = previousItems
                    self.loadingState = .loaded(previousItems)
                }
                self.isLoading = false
            }
        }
    }

    func create(request: CreateRecurrenceRequestDto) async -> Bool {
        do {
            let _: CreateRecurrenceResponseDto = try await apiClient.request(
                "/api/v1/recurrences",
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

    func update(id: String, request: UpdateRecurrenceRequestDto) async -> Bool {
        do {
            let _: RecurrenceResponseDto = try await apiClient.request(
                "/api/v1/recurrences/\(id)",
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
                "/api/v1/recurrences/\(id)",
                method: "DELETE"
            )
            await load()
        } catch {
            errorMessage = error.userMessage
        }
    }

    func pause(id: String) async {
        do {
            let _: RecurrenceResponseDto = try await apiClient.request(
                "/api/v1/recurrences/\(id)/pause",
                method: "POST"
            )
            await load()
        } catch {
            errorMessage = error.userMessage
        }
    }

    func resume(id: String) async {
        do {
            let _: RecurrenceResponseDto = try await apiClient.request(
                "/api/v1/recurrences/\(id)/resume",
                method: "POST"
            )
            await load()
        } catch {
            errorMessage = error.userMessage
        }
    }
}
