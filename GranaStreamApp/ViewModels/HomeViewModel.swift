import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var selectedPeriod: HomePeriod = .monthly
    @Published var loadingState: LoadingState<DashboardHomeResponseDto> = .idle
    @Published var accountCards: [HomeAccountCardItem] = []
    @Published var errorMessage: String?

    private let apiClient: APIClientProtocol
    private let taskManager = TaskManager()
    private var latestLoadRequestId = UUID()

    init(apiClient: APIClientProtocol? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    var dashboard: DashboardHomeResponseDto? {
        loadingState.data
    }

    var isLoading: Bool {
        loadingState.isLoading
    }

    var chartBucket: DashboardChartBucket {
        if selectedPeriod == .daily {
            return .week
        }
        if selectedPeriod == .weekly {
            return .week
        }
        if selectedPeriod == .monthly {
            return .month
        }
        if selectedPeriod == .yearly {
            return .year
        }
        return DashboardChartBucket.fromServerValue(dashboard?.chart?.bucket)
    }

    var chartPoints: [DashboardChartPointResponseDto] {
        dashboard?.chart?.points ?? []
    }

    var recentTransactions: [DashboardRecentTransactionResponseDto] {
        dashboard?.recentTransactions ?? []
    }

    var totalBalance: Double {
        dashboard?.summary?.totalBalance ?? 0
    }

    var totalExpense: Double {
        dashboard?.summary?.totalExpense ?? 0
    }

    var totalIncome: Double {
        dashboard?.summary?.totalIncome ?? 0
    }

    var totalBalanceText: String {
        CurrencyFormatter.string(from: totalBalance)
    }

    var totalExpenseText: String {
        CurrencyFormatter.string(from: -abs(totalExpense))
    }

    var budgetLimitText: String {
        CurrencyFormatter.string(from: budgetLimitAmount)
    }

    var budgetSpentText: String {
        CurrencyFormatter.string(from: budgetSpentAmount)
    }

    var budgetProgress: Double {
        guard budgetLimitAmount > 0 else { return 0 }
        let value = budgetSpentAmount / budgetLimitAmount
        return max(0, min(value, 1))
    }

    var budgetProgressText: String {
        let percent = Int(round(budgetProgress * 100))
        return "\(percent)%"
    }

    var isEmptyState: Bool {
        chartPoints.isEmpty && recentTransactions.isEmpty
    }

    var hasInitialLoading: Bool {
        if case .loading(let previousData) = loadingState {
            return previousData == nil
        }
        return false
    }

    var fullScreenErrorMessage: String? {
        if case .error(let message) = loadingState, dashboard == nil {
            return message
        }
        return nil
    }

    func selectPeriod(_ period: HomePeriod, referenceDate: Date = Date()) async {
        guard period != selectedPeriod else { return }
        selectedPeriod = period
        await load(referenceDate: referenceDate)
    }

    func load(referenceDate: Date = Date()) async {
        let requestId = UUID()
        latestLoadRequestId = requestId

        await taskManager.executeAndWait(id: "home.load") {
            let previousData = self.dashboard
            self.loadingState = .loading(previousData: previousData)
            self.errorMessage = nil

            do {
                let response: DashboardHomeResponseDto = try await self.apiClient.request(
                    "/api/v1/dashboard/home",
                    queryItems: [
                        URLQueryItem(name: "period", value: self.selectedPeriod.apiValue),
                        URLQueryItem(name: "referenceDate", value: DateCoder.string(from: referenceDate))
                    ]
                )

                guard self.latestLoadRequestId == requestId else { return }

                if self.selectedPeriod != .daily,
                   let responsePeriod = HomePeriod.fromServerValue(response.period) {
                    self.selectedPeriod = responsePeriod
                }

                self.loadingState = .loaded(response)
                self.errorMessage = nil
                await self.loadAccountCards(requestId: requestId)
            } catch {
                guard self.latestLoadRequestId == requestId else { return }
                if error.isCancellation {
                    return
                }

                let message = error.userMessage ?? L10n.Home.errorDefault
                self.errorMessage = message
                if let previousData {
                    self.loadingState = .loaded(previousData)
                } else {
                    self.loadingState = .error(message)
                }
            }
        }
    }

    private var budgetLimitAmount: Double {
        max(0, dashboard?.budget?.limitAmount ?? 0)
    }

    private var budgetSpentAmount: Double {
        max(0, dashboard?.budget?.spentAmount ?? 0)
    }

    private func loadAccountCards(requestId: UUID) async {
        let accounts: [AccountResponseDto]

        do {
            accounts = try await apiClient.request("/api/v1/accounts")
        } catch {
            guard latestLoadRequestId == requestId else { return }
            accountCards = []
            return
        }

        guard latestLoadRequestId == requestId else { return }

        let summary: AccountsSummaryResponseDto?
        do {
            summary = try await apiClient.request("/api/v1/accounts/summary")
        } catch {
            summary = nil
        }

        guard latestLoadRequestId == requestId else { return }

        var balanceMap: [String: Double] = [:]
        for item in summary?.byAccount ?? [] {
            balanceMap[item.accountId] = item.balance
        }

        accountCards = accounts.map { account in
            let accountName = (account.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let resolvedName = accountName.isEmpty ? "Conta" : accountName
            return HomeAccountCardItem(
                accountId: account.id,
                name: resolvedName,
                accountType: account.accountType,
                initialBalance: account.initialBalance,
                currentBalance: balanceMap[account.id] ?? account.initialBalance
            )
        }
    }
}
