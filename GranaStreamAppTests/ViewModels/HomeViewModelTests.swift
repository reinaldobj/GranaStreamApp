import XCTest
@testable import GranaStreamApp

@MainActor
final class HomeViewModelTests: XCTestCase {
    var sut: HomeViewModel!
    var mockAPIClient: MockAPIClient!

    override func setUp() async throws {
        mockAPIClient = MockAPIClient()
        sut = HomeViewModel(apiClient: mockAPIClient)
    }

    override func tearDown() async throws {
        sut = nil
        mockAPIClient = nil
    }

    func testLoad_DefaultPeriod_SendsMonthlyQuery() async {
        let referenceDate = Date(timeIntervalSince1970: 1_739_188_800)
        mockAPIClient.mockResponse = makeDashboardResponse()

        await sut.load(referenceDate: referenceDate)

        let call = mockAPIClient.requestHistoryDetailed.first { $0.path == "/api/v1/dashboard/home" }
        XCTAssertEqual(call?.path, "/api/v1/dashboard/home")
        XCTAssertEqual(call?.method, "GET")
        XCTAssertTrue((call?.queryItems ?? []).contains { $0.name == "period" && $0.value == "month" })
        XCTAssertTrue((call?.queryItems ?? []).contains {
            $0.name == "referenceDate" && $0.value == DateCoder.string(from: referenceDate)
        })
    }

    func testSelectPeriod_ChangesQueryValue() async {
        mockAPIClient.mockResponse = makeDashboardResponse(period: "week")
        await sut.selectPeriod(.weekly, referenceDate: Date())
        XCTAssertTrue(lastDashboardQueryItems().contains { $0.name == "period" && $0.value == "week" })

        mockAPIClient.mockResponse = makeDashboardResponse(period: "day")
        await sut.selectPeriod(.daily, referenceDate: Date())
        XCTAssertTrue(lastDashboardQueryItems().contains { $0.name == "period" && $0.value == "day" })
        XCTAssertEqual(sut.selectedPeriod, .daily)

        mockAPIClient.mockResponse = makeDashboardResponse(period: "year")
        await sut.selectPeriod(.yearly, referenceDate: Date())
        XCTAssertTrue(lastDashboardQueryItems().contains { $0.name == "period" && $0.value == "year" })
    }

    func testLoad_Success_UpdatesDataForUI() async {
        mockAPIClient.mockResponse = makeDashboardResponse(
            summary: DashboardSummaryResponseDto(totalBalance: 7783, totalIncome: 4000, totalExpense: 1187.4),
            budget: DashboardBudgetResponseDto(limitAmount: 20_000, spentAmount: 1187.4, remainingAmount: 18_812.6, utilizationPercent: 5.94),
            points: [
                DashboardChartPointResponseDto(label: "01", runningBalance: 200)
            ],
            recent: [
                DashboardRecentTransactionResponseDto(
                    id: UUID().uuidString,
                    date: Date(),
                    title: "Mercado",
                    categoryName: "Alimentação",
                    type: "expense",
                    amount: 100
                )
            ]
        )

        await sut.load()

        XCTAssertEqual(sut.totalBalanceText, CurrencyFormatter.string(from: 7783))
        XCTAssertEqual(sut.totalExpenseText, CurrencyFormatter.string(from: -1187.4))
        XCTAssertEqual(sut.budgetLimitText, CurrencyFormatter.string(from: 20_000))
        XCTAssertEqual(sut.chartPoints.count, 1)
        XCTAssertEqual(sut.recentTransactions.count, 1)
    }

    func testLoad_EmptyResponse_HandlesZeroState() async {
        mockAPIClient.mockResponse = makeDashboardResponse(
            points: [],
            recent: []
        )

        await sut.load()

        XCTAssertTrue(sut.isEmptyState)
        XCTAssertEqual(sut.chartPoints.count, 0)
        XCTAssertEqual(sut.recentTransactions.count, 0)
        XCTAssertEqual(sut.totalBalance, 0)
    }

    func testLoad_Unauthorized_ShowsError() async {
        mockAPIClient.mockError = APIError.unauthorized

        await sut.load()

        XCTAssertNotNil(sut.errorMessage)
        if case .error = sut.loadingState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected error state")
        }
    }

    func testLoad_UnprocessableContent_ShowsError() async {
        let problem = ProblemDetails(
            type: nil,
            title: "Dados inválidos",
            status: 422,
            detail: "Período inválido",
            instance: nil,
            errors: nil,
            accountId: nil
        )
        mockAPIClient.mockError = APIError.server(status: 422, problem: problem)

        await sut.load()

        XCTAssertNotNil(sut.errorMessage)
        if case .error = sut.loadingState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected error state")
        }
    }

    func testLoad_UnexpectedStringValues_DoesNotBreak() async {
        mockAPIClient.mockResponse = makeDashboardResponse(
            period: "strange",
            bucket: "unknown",
            recent: [
                DashboardRecentTransactionResponseDto(
                    id: UUID().uuidString,
                    date: Date(),
                    title: "Item",
                    categoryName: "Categoria",
                    type: "invalid-value",
                    amount: 10
                )
            ]
        )

        await sut.load()

        XCTAssertEqual(sut.selectedPeriod, .monthly)
        XCTAssertEqual(sut.chartBucket, .month)
        XCTAssertNil(sut.recentTransactions.first?.resolvedType)
    }

    func testLoad_PeriodYear_ComesFromBackend() async {
        mockAPIClient.mockResponse = makeDashboardResponse(period: "year")

        await sut.load()

        XCTAssertEqual(sut.selectedPeriod, .yearly)
    }

    func testLoad_MapsAccountCards_WithSummaryFallback() async {
        mockAPIClient.mockResponsesByPath["/api/v1/dashboard/home"] = makeDashboardResponse()
        mockAPIClient.mockResponsesByPath["/api/v1/accounts"] = [
            AccountResponseDto(id: "1", name: "Carteira", initialBalance: 100, accountType: .carteira),
            AccountResponseDto(id: "2", name: "Banco", initialBalance: 250, accountType: .contaCorrente)
        ]
        mockAPIClient.mockResponsesByPath["/api/v1/accounts/summary"] = AccountsSummaryResponseDto(
            totalBalance: 999,
            byAccount: [
                AccountBalanceDto(accountId: "1", accountName: "Carteira", balance: 850)
            ],
            calculatedAt: Date()
        )

        await sut.load()

        XCTAssertEqual(sut.accountCards.count, 2)
        XCTAssertEqual(sut.accountCards.first?.accountId, "1")
        XCTAssertEqual(sut.accountCards.first?.currentBalance, 850)
        XCTAssertEqual(sut.accountCards.last?.currentBalance, 250) // fallback para saldo inicial
    }

    func testLoad_WhenSummaryFails_UsesInitialBalance() async {
        mockAPIClient.mockResponsesByPath["/api/v1/dashboard/home"] = makeDashboardResponse()
        mockAPIClient.mockResponsesByPath["/api/v1/accounts"] = [
            AccountResponseDto(id: "1", name: "Carteira", initialBalance: 120, accountType: .carteira)
        ]
        mockAPIClient.mockErrorsByPath["/api/v1/accounts/summary"] = APIError.network

        await sut.load()

        XCTAssertEqual(sut.accountCards.count, 1)
        XCTAssertEqual(sut.accountCards.first?.currentBalance, 120)
    }

    func testLoad_WhenAccountsFail_HidesCardsAndKeepsDashboardData() async {
        mockAPIClient.mockResponsesByPath["/api/v1/dashboard/home"] = makeDashboardResponse(
            summary: DashboardSummaryResponseDto(totalBalance: 500, totalIncome: 1000, totalExpense: 500)
        )
        mockAPIClient.mockErrorsByPath["/api/v1/accounts"] = APIError.network

        await sut.load()

        XCTAssertEqual(sut.totalBalance, 500)
        XCTAssertTrue(sut.accountCards.isEmpty)
    }

    private func makeDashboardResponse(
        period: String = "month",
        bucket: String = "day",
        summary: DashboardSummaryResponseDto = DashboardSummaryResponseDto(totalBalance: 0, totalIncome: 0, totalExpense: 0),
        budget: DashboardBudgetResponseDto = DashboardBudgetResponseDto(limitAmount: 0, spentAmount: 0, remainingAmount: 0, utilizationPercent: 0),
        points: [DashboardChartPointResponseDto] = [
            DashboardChartPointResponseDto(label: "01", runningBalance: 0)
        ],
        recent: [DashboardRecentTransactionResponseDto] = []
    ) -> DashboardHomeResponseDto {
        DashboardHomeResponseDto(
            period: period,
            range: DashboardRangeResponseDto(
                start: Date(),
                end: Date(),
                timezone: "America/Sao_Paulo"
            ),
            summary: summary,
            budget: budget,
            chart: DashboardChartResponseDto(bucket: bucket, openingBalance: 0, points: points),
            recentTransactions: recent,
            meta: DashboardMetaResponseDto(
                recentLimit: 20,
                generatedAt: Date(),
                timezone: "America/Sao_Paulo"
            )
        )
    }

    private func lastDashboardQueryItems() -> [URLQueryItem] {
        mockAPIClient.requestHistoryDetailed
            .reversed()
            .first(where: { $0.path == "/api/v1/dashboard/home" })?
            .queryItems ?? []
    }
}
