import XCTest
@testable import GranaStreamApp

@MainActor
final class AccountDetailViewModelTests: XCTestCase {
    var sut: AccountDetailViewModel!
    var mockAPIClient: MockAPIClient!

    override func setUp() async throws {
        mockAPIClient = MockAPIClient()
        sut = AccountDetailViewModel(account: makeAccount(), apiClient: mockAPIClient)
    }

    override func tearDown() async throws {
        sut = nil
        mockAPIClient = nil
    }

    func testLoad_Success_UpdatesBalanceCountsAndTransactions() async {
        mockAPIClient.mockResponsesByPath["/api/v1/accounts/summary"] = makeSummary(balance: 950)
        mockAPIClient.mockResponseQueueByPath["/api/v1/transactions"] = [
            makeTransactionsResponse(
                items: [
                    TransactionSummaryDto(
                        id: "2",
                        type: .expense,
                        date: Date(timeIntervalSince1970: 1_738_000_000),
                        description: "Mercado",
                        amount: 90,
                        accountId: "acc-1",
                        accountName: "Carteira",
                        categoryId: nil,
                        categoryName: nil,
                        fromAccountId: nil,
                        fromAccountName: nil,
                        toAccountId: nil,
                        toAccountName: nil,
                        summary: nil
                    ),
                    TransactionSummaryDto(
                        id: "1",
                        type: .income,
                        date: Date(timeIntervalSince1970: 1_739_000_000),
                        description: "Salário",
                        amount: 2200,
                        accountId: "acc-1",
                        accountName: "Carteira",
                        categoryId: nil,
                        categoryName: nil,
                        fromAccountId: nil,
                        fromAccountName: nil,
                        toAccountId: nil,
                        toAccountName: nil,
                        summary: nil
                    )
                ],
                total: 2
            ),
            makeTransactionsResponse(items: [], total: 7),
            makeTransactionsResponse(items: [], total: 3),
            makeTransactionsResponse(items: [], total: 2)
        ]

        await sut.load()

        XCTAssertEqual(sut.currentBalance, 950)
        XCTAssertEqual(sut.incomeCount, 7)
        XCTAssertEqual(sut.expenseCount, 3)
        XCTAssertEqual(sut.transferCount, 2)
        XCTAssertEqual(sut.transactions.count, 2)
        XCTAssertEqual(sut.transactions.first?.id, "1")
    }

    func testLoad_WhenSummaryFails_UsesInitialBalance() async {
        mockAPIClient.mockErrorsByPath["/api/v1/accounts/summary"] = APIError.network
        mockAPIClient.mockResponseQueueByPath["/api/v1/transactions"] = [
            makeTransactionsResponse(items: [], total: 0),
            makeTransactionsResponse(items: [], total: 1),
            makeTransactionsResponse(items: [], total: 2),
            makeTransactionsResponse(items: [], total: 3)
        ]

        await sut.load()

        XCTAssertEqual(sut.currentBalance, 100)
        XCTAssertEqual(sut.incomeCount, 1)
        XCTAssertEqual(sut.expenseCount, 2)
        XCTAssertEqual(sut.transferCount, 3)
    }

    func testLoad_EmptyResponse_HandlesZeroState() async {
        mockAPIClient.mockResponsesByPath["/api/v1/accounts/summary"] = makeSummary(balance: 100)
        mockAPIClient.mockResponseQueueByPath["/api/v1/transactions"] = [
            makeTransactionsResponse(items: [], total: 0),
            makeTransactionsResponse(items: [], total: 0),
            makeTransactionsResponse(items: [], total: 0),
            makeTransactionsResponse(items: [], total: 0)
        ]

        await sut.load()

        XCTAssertTrue(sut.transactions.isEmpty)
        XCTAssertEqual(sut.incomeCount, 0)
        XCTAssertEqual(sut.expenseCount, 0)
        XCTAssertEqual(sut.transferCount, 0)
    }

    func testLoad_NetworkError_ShowsMessage() async {
        mockAPIClient.mockError = APIError.network

        await sut.load()

        XCTAssertNotNil(sut.errorMessage)
        if case .error = sut.loadingState {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected error state")
        }
    }

    func testLoad_SendsMonthDateRangeAndAccountFilter() async {
        mockAPIClient.mockResponsesByPath["/api/v1/accounts/summary"] = makeSummary(balance: 200)
        mockAPIClient.mockResponseQueueByPath["/api/v1/transactions"] = [
            makeTransactionsResponse(items: [], total: 0),
            makeTransactionsResponse(items: [], total: 0),
            makeTransactionsResponse(items: [], total: 0),
            makeTransactionsResponse(items: [], total: 0)
        ]

        await sut.load()

        let transactionCalls = mockAPIClient.requestHistoryDetailed.filter { $0.path == "/api/v1/transactions" }
        XCTAssertEqual(transactionCalls.count, 4)

        for call in transactionCalls {
            XCTAssertTrue(call.queryItems.contains { $0.name == "accountId" && $0.value == "acc-1" })
            XCTAssertTrue(call.queryItems.contains { $0.name == "startDate" })
            XCTAssertTrue(call.queryItems.contains { $0.name == "endDate" })
        }

        let typedCalls = transactionCalls.filter { $0.queryItems.contains(where: { $0.name == "type" }) }
        XCTAssertEqual(typedCalls.count, 3)
    }

    private func makeAccount() -> HomeAccountCardItem {
        HomeAccountCardItem(
            accountId: "acc-1",
            name: "Carteira",
            accountType: .carteira,
            initialBalance: 100,
            currentBalance: 150
        )
    }

    private func makeSummary(balance: Double) -> AccountsSummaryResponseDto {
        AccountsSummaryResponseDto(
            totalBalance: balance,
            byAccount: [
                AccountBalanceDto(accountId: "acc-1", accountName: "Carteira", balance: balance)
            ],
            calculatedAt: Date()
        )
    }

    private func makeTransactionsResponse(items: [TransactionSummaryDto], total: Int) -> ListTransactionsResponseDto {
        ListTransactionsResponseDto(
            items: items,
            page: 1,
            size: 20,
            total: total,
            links: PaginationLinksDto(first: nil, previous: nil, next: nil, last: nil)
        )
    }
}
