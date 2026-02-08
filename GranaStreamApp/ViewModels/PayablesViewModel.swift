import Foundation
import SwiftUI
import Combine

/// Filtro de status de contas a pagar
enum PayablesStatusFilter: String, CaseIterable, Identifiable {
    case pending
    case settled

    var id: String { rawValue }

    var label: String {
        switch self {
        case .pending:
            return "Pendentes"
        case .settled:
            return "Quitados"
        }
    }

    var queryValue: String {
        switch self {
        case .pending:
            return "Pending"
        case .settled:
            return "Settled"
        }
    }

    var payableStatus: PayableStatus {
        switch self {
        case .pending:
            return .pending
        case .settled:
            return .settled
        }
    }
}

/// ViewModel para gerenciar contas a pagar com fallback de requisição
@MainActor
final class PayablesViewModel: ObservableObject {
    @Published var loadingState: LoadingState<[PayableListItemDto]> = .idle
    @Published var errorMessage: String?
    @Published private(set) var settlingIds: Set<String> = []
    @Published private(set) var undoingIds: Set<String> = []
    
    var items: [PayableListItemDto] {
        if case .loaded(let data) = loadingState {
            return data
        }
        return []
    }
    
    var isLoading: Bool {
        if case .loading = loadingState {
            return true
        }
        return false
    }

    private let apiClient: APIClientProtocol
    private let taskManager = TaskManager()
    
    init(apiClient: APIClientProtocol? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    func load(month: Date, statusFilter: PayablesStatusFilter) async {
        taskManager.execute(id: "load") {
            self.loadingState = .loading
            self.errorMessage = nil

            do {
                let items = try await self.fetchPayables(month: month, statusFilter: statusFilter)
                self.loadingState = .loaded(items)
            } catch {
                let message = error.userMessage ?? "Erro ao carregar contas a pagar"
                self.errorMessage = message
                self.loadingState = .error(message)
            }
        }
    }

    func settle(payableId: String, request: SettlePayableRequestDto) async -> SettlePayableResponseDto? {
        guard !settlingIds.contains(payableId) else { return nil }

        settlingIds.insert(payableId)
        defer { settlingIds.remove(payableId) }

        do {
            let response: SettlePayableResponseDto = try await apiClient.request(
                "/api/v1/payables/\(payableId)/settle",
                method: "POST",
                body: AnyEncodable(request)
            )
            return response
        } catch {
            errorMessage = error.userMessage
            return nil
        }
    }

    func isSettling(payableId: String) -> Bool {
        settlingIds.contains(payableId)
    }

    func undoSettlement(payableId: String) async -> UndoSettlePayableResponseDto? {
        guard !undoingIds.contains(payableId) else { return nil }

        undoingIds.insert(payableId)
        defer { undoingIds.remove(payableId) }

        do {
            let response: UndoSettlePayableResponseDto = try await apiClient.request(
                "/api/v1/payables/\(payableId)/settle/undo",
                method: "POST"
            )
            return response
        } catch {
            errorMessage = error.userMessage
            return nil
        }
    }

    func isUndoing(payableId: String) -> Bool {
        undoingIds.contains(payableId)
    }

    // MARK: - Private

    private func fetchPayables(month: Date, statusFilter: PayablesStatusFilter) async throws -> [PayableListItemDto] {
        let monthValue = Self.monthFormatter.string(from: month)
        
        do {
            // Tentar com filtro de status
            return try await fetchWithStatus(monthValue: monthValue, statusFilter: statusFilter)
        } catch {
            // Fallback: tentar sem status se requisição falhar com erro 400 ou 422
            if shouldFallbackWithoutStatus(error) {
                return try await fetchWithoutStatus(monthValue: monthValue, statusFilter: statusFilter)
            }
            throw error
        }
    }

    private func fetchWithStatus(monthValue: String, statusFilter: PayablesStatusFilter) async throws -> [PayableListItemDto] {
        let response: ListPayablesResponseDto = try await apiClient.request(
            "/api/v1/payables",
            queryItems: [
                URLQueryItem(name: "month", value: monthValue),
                URLQueryItem(name: "status", value: statusFilter.queryValue)
            ]
        )
        return Self.sort(items: response.items ?? [])
    }

    private func fetchWithoutStatus(monthValue: String, statusFilter: PayablesStatusFilter) async throws -> [PayableListItemDto] {
        let response: ListPayablesResponseDto = try await apiClient.request(
            "/api/v1/payables",
            queryItems: [
                URLQueryItem(name: "month", value: monthValue)
            ]
        )
        
        // Filtrar localmente quando API não suporta status
        let filtered = (response.items ?? []).filter { item in
            item.status == statusFilter.payableStatus
        }
        return Self.sort(items: filtered)
    }

    private func shouldFallbackWithoutStatus(_ error: Error) -> Bool {
        guard case let APIError.server(status, _) = error else {
            return false
        }
        return status == 400 || status == 422
    }

    private static func sort(items: [PayableListItemDto]) -> [PayableListItemDto] {
        items.sorted { lhs, rhs in
            if lhs.dueDate == rhs.dueDate {
                return (lhs.description ?? "").localizedCaseInsensitiveCompare(rhs.description ?? "") == .orderedAscending
            }
            return lhs.dueDate < rhs.dueDate
        }
    }

    private static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM"
        return formatter
    }()
}
