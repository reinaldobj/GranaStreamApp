import Foundation
import Combine

@MainActor
final class RecurrencesViewModel: ObservableObject {
    @Published var recurrences: [RecurrenceResponseDto] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response: [RecurrenceResponseDto] = try await APIClient.shared.request("/api/v1/recurrences")
            recurrences = response
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func create(request: CreateRecurrenceRequestDto) async -> Bool {
        do {
            let _: CreateRecurrenceResponseDto = try await APIClient.shared.request(
                "/api/v1/recurrences",
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

    func update(id: String, request: UpdateRecurrenceRequestDto) async -> Bool {
        do {
            let _: RecurrenceResponseDto = try await APIClient.shared.request(
                "/api/v1/recurrences/\(id)",
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
                "/api/v1/recurrences/\(id)",
                method: "DELETE"
            )
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func pause(id: String) async {
        do {
            let _: RecurrenceResponseDto = try await APIClient.shared.request(
                "/api/v1/recurrences/\(id)/pause",
                method: "POST"
            )
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func resume(id: String) async {
        do {
            let _: RecurrenceResponseDto = try await APIClient.shared.request(
                "/api/v1/recurrences/\(id)/resume",
                method: "POST"
            )
            await load()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
