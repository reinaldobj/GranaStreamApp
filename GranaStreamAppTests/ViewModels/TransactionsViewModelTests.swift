import XCTest
@testable import GranaStreamApp

@MainActor
final class TransactionsViewModelTests: XCTestCase {
    var sut: TransactionsViewModel!
    var mockAPIClient: MockAPIClient!
    
    override func setUp() async throws {
        mockAPIClient = MockAPIClient()
        sut = TransactionsViewModel(apiClient: mockAPIClient)
    }
    
    override func tearDown() async throws {
        sut = nil
        mockAPIClient = nil
    }
    
    // MARK: - Initialization Tests
    
    func testInit_SetsDefaultFilters() {
        // Given/When - ViewModel is initialized in setUp
        
        // Then
        XCTAssertNotNil(sut.filters.startDate)
        XCTAssertNotNil(sut.filters.endDate)
        XCTAssertNil(sut.filters.type)
        XCTAssertNil(sut.filters.accountId)
        XCTAssertNil(sut.filters.categoryId)
        XCTAssertTrue(sut.filters.searchText.isEmpty)
    }
    
    func testInit_StartsWithEmptyTransactions() {
        // Given/When - ViewModel is initialized in setUp
        
        // Then
        XCTAssertTrue(sut.transactions.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertEqual(sut.incomeTotal, 0)
        XCTAssertEqual(sut.expenseTotal, 0)
    }
    
    // MARK: - Load Tests
    
    func testLoad_Success_UpdatesTransactions() async {
        // Given
        let mockTransactions = [
            TransactionSummaryDto(
                id: "1",
                type: .income,
                date: Date(),
                description: "Salary",
                amount: 5000,
                accountId: "acc1",
                accountName: "Bank",
                categoryId: "cat1",
                categoryName: "Income",
                fromAccountId: nil,
                fromAccountName: nil,
                toAccountId: nil,
                toAccountName: nil,
                summary: "Salary"
            ),
            TransactionSummaryDto(
                id: "2",
                type: .expense,
                date: Date(),
                description: "Groceries",
                amount: 200,
                accountId: "acc1",
                accountName: "Bank",
                categoryId: "cat2",
                categoryName: "Food",
                fromAccountId: nil,
                fromAccountName: nil,
                toAccountId: nil,
                toAccountName: nil,
                summary: "Groceries"
            )
        ]
        
        let mockResponse = ListTransactionsResponseDto(
            items: mockTransactions,
            page: 1,
            size: 20,
            total: 2,
            links: PaginationLinksDto(first: nil, previous: nil, next: nil, last: nil)
        )
        
        mockAPIClient.mockResponse = mockResponse
        
        // When
        await sut.load(reset: true)
        
        // Then
        XCTAssertEqual(mockAPIClient.requestCallCount, 1)
        XCTAssertEqual(mockAPIClient.lastPath, "/api/v1/transactions")
        XCTAssertEqual(mockAPIClient.lastMethod, "GET")
        XCTAssertEqual(sut.transactions.count, 2)
        XCTAssertEqual(sut.incomeTotal, 5000)
        XCTAssertEqual(sut.expenseTotal, 200)
        XCTAssertEqual(sut.totalBalance, 4800)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testLoad_Failure_SetsErrorMessage() async {
        // Given
        mockAPIClient.mockError = APIError.network
        
        // When
        await sut.load(reset: true)
        
        // Then
        XCTAssertEqual(mockAPIClient.requestCallCount, 1)
        XCTAssertTrue(sut.transactions.isEmpty)
        XCTAssertNotNil(sut.errorMessage)
    }
    
    func testLoad_SetsLoadingState() async {
        // Given
        mockAPIClient.requestDelay = 0.1
        mockAPIClient.mockResponse = ListTransactionsResponseDto(
            items: [],
            page: 1,
            size: 20,
            total: 0,
            links: PaginationLinksDto(first: nil, previous: nil, next: nil, last: nil)
        )
        
        // When
        let loadTask = Task {
            await sut.load(reset: true)
        }
        
        // Then - check loading state during request
        try? await Task.sleep(nanoseconds: 10_000_000) // 0.01s
        XCTAssertTrue(sut.isLoading)
        
        await loadTask.value
        XCTAssertFalse(sut.isLoading)
    }
    
    func testLoad_WithFilters_SendsCorrectQueryItems() async {
        // Given
        sut.filters.type = .expense
        sut.filters.accountId = "acc123"
        sut.filters.categoryId = "cat456"
        sut.filters.searchText = "test"
        
        mockAPIClient.mockResponse = ListTransactionsResponseDto(
            items: [],
            page: 1,
            size: 20,
            total: 0,
            links: PaginationLinksDto(first: nil, previous: nil, next: nil, last: nil)
        )
        
        // When
        await sut.load(reset: true)
        
        // Then
        let queryItems = mockAPIClient.lastQueryItems ?? []
        XCTAssertTrue(queryItems.contains { $0.name == "type" && $0.value == "2" })
        XCTAssertTrue(queryItems.contains { $0.name == "accountId" && $0.value == "acc123" })
        XCTAssertTrue(queryItems.contains { $0.name == "categoryId" && $0.value == "cat456" })
        XCTAssertTrue(queryItems.contains { $0.name == "searchText" && $0.value == "test" })
    }
    
    // MARK: - LoadMore Tests
    
    func testLoadMore_Success_AppendsTransactions() async {
        // Given - First load
        let firstBatch = [
            TransactionSummaryDto(
                id: "1",
                type: .income,
                date: Date(),
                description: "First",
                amount: 100,
                accountId: "acc1",
                accountName: "Bank",
                categoryId: nil,
                categoryName: nil,
                fromAccountId: nil,
                fromAccountName: nil,
                toAccountId: nil,
                toAccountName: nil,
                summary: "First"
            )
        ]
        
        mockAPIClient.mockResponse = ListTransactionsResponseDto(
            items: firstBatch,
            page: 1,
            size: 20,
            total: 2,
            links: PaginationLinksDto(first: nil, previous: nil, next: nil, last: nil)
        )
        
        await sut.load(reset: true)
        
        // Given - Second load
        let secondBatch = [
            TransactionSummaryDto(
                id: "2",
                type: .expense,
                date: Date(),
                description: "Second",
                amount: 50,
                accountId: "acc1",
                accountName: "Bank",
                categoryId: nil,
                categoryName: nil,
                fromAccountId: nil,
                fromAccountName: nil,
                toAccountId: nil,
                toAccountName: nil,
                summary: "Second"
            )
        ]
        
        mockAPIClient.mockResponse = ListTransactionsResponseDto(
            items: secondBatch,
            page: 2,
            size: 20,
            total: 2,
            links: PaginationLinksDto(first: nil, previous: nil, next: nil, last: nil)
        )
        
        // When
        await sut.loadMore()
        
        // Then
        XCTAssertEqual(sut.transactions.count, 2)
        XCTAssertEqual(sut.transactions[0].id, "1")
        XCTAssertEqual(sut.transactions[1].id, "2")
    }
    
    func testLoadMore_WhenNoMoreData_DoesNotLoad() async {
        // Given
        mockAPIClient.mockResponse = ListTransactionsResponseDto(
            items: [],
            page: 1,
            size: 20,
            total: 0,
            links: PaginationLinksDto(first: nil, previous: nil, next: nil, last: nil)
        )
        
        await sut.load(reset: true)
        mockAPIClient.reset()
        
        // When
        await sut.loadMore()
        
        // Then
        XCTAssertEqual(mockAPIClient.requestCallCount, 0)
        XCTAssertFalse(sut.canLoadMore)
    }
    
    // MARK: - Delete Tests
    
    func testDelete_Success_ReloadsTransactions() async {
        // Given
        let transaction = TransactionSummaryDto(
            id: "123",
            type: .expense,
            date: Date(),
            description: "To delete",
            amount: 100,
            accountId: nil,
            accountName: nil,
            categoryId: nil,
            categoryName: nil,
            fromAccountId: nil,
            fromAccountName: nil,
            toAccountId: nil,
            toAccountName: nil,
            summary: nil
        )
        
        mockAPIClient.mockResponse = ListTransactionsResponseDto(
            items: [],
            page: 1,
            size: 20,
            total: 0,
            links: PaginationLinksDto(first: nil, previous: nil, next: nil, last: nil)
        )
        
        // When
        await sut.delete(transaction: transaction)
        
        // Then
        XCTAssertEqual(mockAPIClient.requestNoResponseCallCount, 1)
        XCTAssertEqual(mockAPIClient.lastPath, "/api/v1/transactions/123")
        XCTAssertEqual(mockAPIClient.lastMethod, "DELETE")
        XCTAssertEqual(mockAPIClient.requestCallCount, 1) // load was called
    }
    
    func testDelete_Failure_SetsErrorMessage() async {
        // Given
        let transaction = TransactionSummaryDto(
            id: "123",
            type: .expense,
            date: Date(),
            description: "To delete",
            amount: 100,
            accountId: nil,
            accountName: nil,
            categoryId: nil,
            categoryName: nil,
            fromAccountId: nil,
            fromAccountName: nil,
            toAccountId: nil,
            toAccountName: nil,
            summary: nil
        )
        
        mockAPIClient.mockError = APIError.network
        
        // When
        await sut.delete(transaction: transaction)
        
        // Then
        XCTAssertNotNil(sut.errorMessage)
    }
    
    // MARK: - Calculation Tests
    
    func testTotalBalance_Calculation() {
        // Given
        sut.incomeTotal = 5000
        sut.expenseTotal = 2000
        
        // When
        let balance = sut.totalBalance
        
        // Then
        XCTAssertEqual(balance, 3000)
    }
}
