import Foundation
import SwiftUI
import Combine

struct TransactionMonthSection: Identifiable {
    let id: String
    let title: String
    let items: [TransactionSummaryDto]
}

/// ViewModel para gerenciar transações com filtros e paginação
@MainActor
final class TransactionsViewModel: ObservableObject {
    @Published var loadingState: LoadingState<[TransactionSummaryDto]> = .idle
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var filters: TransactionFilters
    @Published private(set) var monthSections: [TransactionMonthSection] = []
    @Published private(set) var incomeTotal: Double = 0
    @Published private(set) var expenseTotal: Double = 0
    
    var transactions: [TransactionSummaryDto] {
        if case .loaded(let items) = loadingState {
            return items
        }
        return []
    }
    
    var isLoading: Bool {
        if case .loading = loadingState {
            return true
        }
        return false
    }

    private var page = 1
    private let size = 20
    private var total = 0
    private let apiClient: APIClientProtocol
    private let taskManager = TaskManager()

    var totalBalance: Double {
        incomeTotal - expenseTotal
    }

    init(apiClient: APIClientProtocol? = nil) {
        let now = Date()
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? now
        self.filters = TransactionFilters(startDate: start, endDate: end)
        self.apiClient = apiClient ?? APIClient.shared
    }

    var canLoadMore: Bool {
        transactions.count < total
    }

    func load(reset: Bool = false) async {
        taskManager.execute(id: "load") {
            if reset {
                self.page = 1
                self.total = 0
            }
            self.loadingState = .loading
            
            do {
                let items = self.buildQueryItems(page: self.page)
                let response: ListTransactionsResponseDto = try await self.apiClient.request(
                    "/api/v1/transactions",
                    queryItems: items
                )
                self.total = response.total
                let newItems = response.items ?? []
                let allItems = self.page == 1 ? newItems : (self.transactions + newItems)
                self.loadingState = .loaded(allItems)
                self.recalculateDerivedData()
                self.errorMessage = nil
            } catch {
                let message = error.userMessage ?? "Erro ao carregar transações"
                self.errorMessage = message
                self.loadingState = .error(message)
            }
        }
    }

    func loadMore() async {
        guard canLoadMore, !isLoadingMore else { return }
        isLoadingMore = true
        let nextPage = page + 1
        defer { isLoadingMore = false }

        do {
            let items = buildQueryItems(page: nextPage)
            let response: ListTransactionsResponseDto = try await apiClient.request(
                "/api/v1/transactions",
                queryItems: items
            )
            total = response.total
            page = nextPage
            let allItems = transactions + (response.items ?? [])
            loadingState = .loaded(allItems)
            recalculateDerivedData()
        } catch {
            errorMessage = error.userMessage
        }
    }

    func delete(transaction: TransactionSummaryDto) async {
        do {
            try await apiClient.requestNoResponse(
                "/api/v1/transactions/\(transaction.id)",
                method: "DELETE"
            )
            await load(reset: true)
        } catch {
            errorMessage = error.userMessage
        }
    }

    // MARK: - Private

    private func buildQueryItems(page: Int) -> [URLQueryItem] {
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
        
        return items
    }

    private func recalculateDerivedData() {
        incomeTotal = transactions
            .filter { $0.type == .income }
            .reduce(0) { $0 + $1.amount }

        expenseTotal = transactions
            .filter { $0.type == .expense }
            .reduce(0) { $0 + $1.amount }

        monthSections = buildMonthSections(from: transactions)
    }

    private func buildMonthSections(from items: [TransactionSummaryDto]) -> [TransactionMonthSection] {
        let sorted = items.sorted { $0.date > $1.date }
        guard !sorted.isEmpty else { return [] }

        let calendar = Calendar.current
        let years = Set(sorted.map { calendar.component(.year, from: $0.date) })
        let showYear = years.count > 1

        var sections: [TransactionMonthSection] = []
        var currentKey = ""
        var currentDate = Date()
        var currentItems: [TransactionSummaryDto] = []

        for item in sorted {
            let components = calendar.dateComponents([.year, .month], from: item.date)
            let key = String(format: "%04d-%02d", components.year ?? 0, components.month ?? 0)
            if key != currentKey {
                if !currentItems.isEmpty {
                    sections.append(
                        TransactionMonthSection(
                            id: currentKey,
                            title: Self.monthTitle(for: currentDate, showYear: showYear),
                            items: currentItems
                        )
                    )
                }
                currentKey = key
                currentDate = item.date
                currentItems = [item]
            } else {
                currentItems.append(item)
            }
        }

        if !currentItems.isEmpty {
            sections.append(
                TransactionMonthSection(
                    id: currentKey,
                    title: Self.monthTitle(for: currentDate, showYear: showYear),
                    items: currentItems
                )
            )
        }

        return sections
    }

    private static func monthTitle(for date: Date, showYear: Bool) -> String {
        let formatter = showYear ? monthFormatterWithYear : monthFormatterNoYear
        let text = formatter.string(from: date)
        return text.prefix(1).uppercased() + text.dropFirst()
    }

    private static let monthFormatterNoYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "LLLL"
        return formatter
    }()

    private static let monthFormatterWithYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "LLLL yyyy"
        return formatter
    }()
}
