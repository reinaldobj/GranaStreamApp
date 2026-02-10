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
        loadingState.data ?? []
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
    private var latestLoadRequestId = UUID()
    private var latestLoadMoreRequestId = UUID()
    private var requestedPages: Set<Int> = []
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
        let requestId = UUID()
        latestLoadRequestId = requestId

        await taskManager.executeAndWait(id: "load") {
            let previousItems = self.transactions

            if reset {
                self.page = 1
                self.total = 0
                self.requestedPages.removeAll()
            }
            self.loadingState = .loading(previousData: previousItems.isEmpty ? nil : previousItems)
            
            do {
                let items = self.buildQueryItems(page: self.page)
                let response: ListTransactionsResponseDto = try await self.apiClient.request(
                    "/api/v1/transactions",
                    queryItems: items
                )

                guard self.latestLoadRequestId == requestId else { return }

                self.total = response.total
                let newItems = response.items ?? []
                let allItems = self.page == 1 ? newItems : (self.transactions + newItems)
                self.requestedPages = [self.page]
                self.loadingState = .loaded(allItems)
                self.recalculateDerivedData()
                self.errorMessage = nil
            } catch {
                guard self.latestLoadRequestId == requestId else { return }
                if error.isCancellation {
                    return
                }

                let message = error.userMessage ?? "Erro ao carregar transações"
                self.errorMessage = message
                if previousItems.isEmpty {
                    self.loadingState = .error(message)
                } else {
                    self.loadingState = .loaded(previousItems)
                }
            }
        }
    }

    func loadMore() async {
        guard canLoadMore, !isLoadingMore else { return }
        isLoadingMore = true
        let nextPage = page + 1
        guard !requestedPages.contains(nextPage) else {
            isLoadingMore = false
            return
        }
        requestedPages.insert(nextPage)

        let requestId = UUID()
        latestLoadMoreRequestId = requestId

        defer { isLoadingMore = false }

        do {
            let items = buildQueryItems(page: nextPage)
            let response: ListTransactionsResponseDto = try await apiClient.request(
                "/api/v1/transactions",
                queryItems: items
            )

            guard latestLoadMoreRequestId == requestId else { return }

            total = response.total
            page = nextPage
            let allItems = transactions + (response.items ?? [])
            loadingState = .loaded(allItems)
            recalculateDerivedData()
        } catch {
            guard latestLoadMoreRequestId == requestId else { return }
            if error.isCancellation {
                requestedPages.remove(nextPage)
                return
            }
            requestedPages.remove(nextPage)
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
        var income: Double = 0
        var expense: Double = 0

        for item in transactions {
            switch item.type {
            case .income:
                income += item.amount
            case .expense:
                expense += item.amount
            case .transfer:
                break
            }
        }

        incomeTotal = income
        expenseTotal = expense

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
