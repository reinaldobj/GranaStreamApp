import Foundation
import Combine

@MainActor
final class TransactionsViewModel: ObservableObject {
    @Published var transactions: [TransactionSummaryDto] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var filters: TransactionFilters

    private var page = 1
    private let size = 20
    private var total = 0

    init() {
        let now = Date()
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? now
        self.filters = TransactionFilters(startDate: start, endDate: end)
    }

    var canLoadMore: Bool {
        transactions.count < total
    }

    func load(reset: Bool = false) async {
        if reset {
            page = 1
            total = 0
        }
        isLoading = true
        defer { isLoading = false }

        do {
            var items: [URLQueryItem] = [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "size", value: String(size)),
                URLQueryItem(name: "startDate", value: DateCoder.string(from: filters.startDate)),
                URLQueryItem(name: "endDate", value: DateCoder.string(from: filters.endDate))
            ]
            if let type = filters.type {
                items.append(URLQueryItem(name: "type", value: String(type.rawValue)))
            }
            if let accountId = filters.accountId {
                items.append(URLQueryItem(name: "accountId", value: accountId))
            }
            if let categoryId = filters.categoryId {
                items.append(URLQueryItem(name: "categoryId", value: categoryId))
            }
            if !filters.searchText.isEmpty {
                items.append(URLQueryItem(name: "searchText", value: filters.searchText))
            }

            let response: ListTransactionsResponseDto = try await APIClient.shared.request(
                "/api/v1/transactions",
                queryItems: items
            )
            total = response.total
            if page == 1 {
                transactions = response.items ?? []
            } else {
                transactions.append(contentsOf: response.items ?? [])
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadMore() async {
        guard canLoadMore, !isLoadingMore else { return }
        isLoadingMore = true
        page += 1
        defer { isLoadingMore = false }

        do {
            var items: [URLQueryItem] = [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "size", value: String(size)),
                URLQueryItem(name: "startDate", value: DateCoder.string(from: filters.startDate)),
                URLQueryItem(name: "endDate", value: DateCoder.string(from: filters.endDate))
            ]
            if let type = filters.type {
                items.append(URLQueryItem(name: "type", value: String(type.rawValue)))
            }
            if let accountId = filters.accountId {
                items.append(URLQueryItem(name: "accountId", value: accountId))
            }
            if let categoryId = filters.categoryId {
                items.append(URLQueryItem(name: "categoryId", value: categoryId))
            }
            if !filters.searchText.isEmpty {
                items.append(URLQueryItem(name: "searchText", value: filters.searchText))
            }

            let response: ListTransactionsResponseDto = try await APIClient.shared.request(
                "/api/v1/transactions",
                queryItems: items
            )
            total = response.total
            transactions.append(contentsOf: response.items ?? [])
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(transaction: TransactionSummaryDto) async {
        do {
            try await APIClient.shared.requestNoResponse(
                "/api/v1/transactions/\(transaction.id)",
                method: "DELETE"
            )
            await load(reset: true)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
