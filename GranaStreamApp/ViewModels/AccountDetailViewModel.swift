import Foundation
import Combine

@MainActor
final class AccountDetailViewModel: ObservableObject {
    @Published var loadingState: LoadingState<[TransactionSummaryDto]> = .idle
    @Published var currentBalance: Double
    @Published var incomeCount: Int = 0
    @Published var expenseCount: Int = 0
    @Published var transferCount: Int = 0
    @Published var errorMessage: String?

    let account: HomeAccountCardItem

    private let apiClient: APIClientProtocol
    private let taskManager = TaskManager()

    init(account: HomeAccountCardItem, apiClient: APIClientProtocol? = nil) {
        self.account = account
        self.currentBalance = account.currentBalance
        self.apiClient = apiClient ?? APIClient.shared
    }

    var transactions: [TransactionSummaryDto] {
        loadingState.data ?? []
    }

    var hasInitialLoading: Bool {
        if case .loading(let previousData) = loadingState {
            return previousData == nil
        }
        return false
    }

    var fullScreenErrorMessage: String? {
        if case .error(let message) = loadingState, transactions.isEmpty {
            return message
        }
        return nil
    }

    var currentBalanceText: String {
        CurrencyFormatter.string(from: currentBalance)
    }

    var initialBalanceText: String {
        CurrencyFormatter.string(from: account.initialBalance)
    }

    func load() async {
        await taskManager.executeAndWait(id: "account.detail.load") {
            let previousData = self.transactions
            self.loadingState = .loading(previousData: previousData.isEmpty ? nil : previousData)
            self.errorMessage = nil

            do {
                let summary: AccountsSummaryResponseDto?
                do {
                    let value: AccountsSummaryResponseDto = try await self.apiClient.request("/api/v1/accounts/summary")
                    summary = value
                } catch {
                    summary = nil
                }

                let recentResponse: ListTransactionsResponseDto = try await self.apiClient.request(
                    "/api/v1/transactions",
                    queryItems: self.queryItems(size: 8, type: nil)
                )
                let incomeCount = try await self.fetchCount(type: .income)
                let expenseCount = try await self.fetchCount(type: .expense)
                let transferCount = try await self.fetchCount(type: .transfer)

                self.currentBalance = self.resolveCurrentBalance(summary: summary)
                self.incomeCount = incomeCount
                self.expenseCount = expenseCount
                self.transferCount = transferCount
                self.loadingState = .loaded((recentResponse.items ?? []).sorted { $0.date > $1.date })
                self.errorMessage = nil
            } catch {
                if error.isCancellation {
                    return
                }

                let message = error.userMessage ?? L10n.Accounts.Detail.errorDefault
                self.errorMessage = message
                if previousData.isEmpty {
                    self.loadingState = .error(message)
                } else {
                    self.loadingState = .loaded(previousData)
                }
            }
        }
    }

    func pendingAdjustBalanceMessage(for amount: Double) -> String {
        guard amount > 0 else {
            return L10n.Accounts.Detail.adjustHint
        }
        return L10n.Accounts.Detail.adjustHint
    }

    private func fetchCount(type: TransactionType) async throws -> Int {
        let response: ListTransactionsResponseDto = try await apiClient.request(
            "/api/v1/transactions",
            queryItems: queryItems(size: 1, type: type)
        )
        return response.total
    }

    private func resolveCurrentBalance(summary: AccountsSummaryResponseDto?) -> Double {
        let map = Dictionary(uniqueKeysWithValues: (summary?.byAccount ?? []).map { ($0.accountId, $0.balance) })
        return map[account.accountId] ?? account.initialBalance
    }

    private func queryItems(size: Int, type: TransactionType?) -> [URLQueryItem] {
        let dateRange = monthDateRange(referenceDate: Date())
        var items: [URLQueryItem] = [
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "size", value: String(size)),
            URLQueryItem(name: "startDate", value: DateCoder.string(from: dateRange.start)),
            URLQueryItem(name: "endDate", value: DateCoder.string(from: dateRange.end)),
            URLQueryItem(name: "accountId", value: account.accountId)
        ]

        if let type {
            items.append(URLQueryItem(name: "type", value: String(type.rawValue)))
        }

        return items
    }

    private func monthDateRange(referenceDate: Date) -> (start: Date, end: Date) {
        let calendar = Calendar.current
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: referenceDate)) ?? referenceDate
        let end = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: start) ?? referenceDate
        return (start, end)
    }
}
