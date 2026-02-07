import Foundation
import Combine // TODO: [TECH-DEBT] Import não utilizado - remover Combine

// TODO: [TECH-DEBT] Fallback complexo em fetchPayables() com try-catch aninhado - simplificar lógica
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

@MainActor
final class PayablesViewModel: ObservableObject {
    @Published private(set) var items: [PayableListItemDto] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var settlingIds: Set<String> = []
    @Published private(set) var undoingIds: Set<String> = []

    func load(month: Date, statusFilter: PayablesStatusFilter) async {
        isLoading = true
        defer { isLoading = false }

        errorMessage = nil

        do {
            items = try await fetchPayables(month: month, statusFilter: statusFilter)
        } catch {
            errorMessage = error.userMessage
        }
    }

    func settle(payableId: String, request: SettlePayableRequestDto) async -> SettlePayableResponseDto? {
        guard !settlingIds.contains(payableId) else { return nil }

        settlingIds.insert(payableId)
        defer { settlingIds.remove(payableId) }

        do {
            let response: SettlePayableResponseDto = try await APIClient.shared.request(
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
            let response: UndoSettlePayableResponseDto = try await APIClient.shared.request(
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

    private func fetchPayables(month: Date, statusFilter: PayablesStatusFilter) async throws -> [PayableListItemDto] {
        let monthValue = Self.monthFormatter.string(from: month)

        do {
            let response: ListPayablesResponseDto = try await APIClient.shared.request(
                "/api/v1/payables",
                queryItems: [
                    URLQueryItem(name: "month", value: monthValue),
                    URLQueryItem(name: "status", value: statusFilter.queryValue)
                ]
            )
            return Self.sort(items: response.items ?? [])
        } catch {
            guard shouldFallbackWithoutStatus(error) else {
                throw error
            }

            let fallbackResponse: ListPayablesResponseDto = try await APIClient.shared.request(
                "/api/v1/payables",
                queryItems: [
                    URLQueryItem(name: "month", value: monthValue)
                ]
            )

            let filtered = (fallbackResponse.items ?? []).filter { item in
                item.status == statusFilter.payableStatus
            }
            return Self.sort(items: filtered)
        }
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
