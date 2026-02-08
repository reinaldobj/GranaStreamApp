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
    
    init(apiClient: APIClientProtocol? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    func load() async {
        isLoading = true
        loadingState = .loading
        defer { isLoading = false }
        do {
            let response: [RecurrenceResponseDto] = try await apiClient.request("/api/v1/recurrences")
            recurrences = response
            loadingState = .loaded(response)
        } catch {
            errorMessage = error.userMessage
            loadingState = .error(error.userMessage ?? "Erro desconhecido")
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
