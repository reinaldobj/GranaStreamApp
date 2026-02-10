import XCTest
@testable import GranaStreamApp

@MainActor
final class AccountsViewModelTests: XCTestCase {
    var sut: AccountsViewModel!
    var mockAPIClient: MockAPIClient!
    
    override func setUp() async throws {
        mockAPIClient = MockAPIClient()
        sut = AccountsViewModel(apiClient: mockAPIClient)
    }
    
    override func tearDown() async throws {
        sut = nil
        mockAPIClient = nil
    }
    
    // MARK: - Initialization Tests
    
    func testInit_StartsWithEmptyAccounts() {
        // Given/When - ViewModel is initialized in setUp
        
        // Then
        XCTAssertTrue(sut.accounts.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertNil(sut.inactiveAccount)
        XCTAssertTrue(sut.activeSearchTerm.isEmpty)
    }
    
    // MARK: - Load Tests
    
    func testLoad_Success_UpdatesAccounts() async {
        // Given
        let mockAccounts = [
            AccountResponseDto(
                id: "1",
                name: "Checking",
                initialBalance: 1000,
                accountType: .contaCorrente
            ),
            AccountResponseDto(
                id: "2",
                name: "Savings",
                initialBalance: 5000,
                accountType: .contaPoupanca
            )
        ]
        
        mockAPIClient.mockResponse = mockAccounts
        
        // When
        await sut.load()
        
        // Then
        XCTAssertEqual(mockAPIClient.requestCallCount, 1)
        XCTAssertEqual(mockAPIClient.lastPath, "/api/v1/accounts")
        XCTAssertEqual(mockAPIClient.lastMethod, "GET")
        XCTAssertEqual(sut.accounts.count, 2)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testLoad_Failure_SetsErrorMessage() async {
        // Given
        mockAPIClient.mockError = APIError.network
        
        // When
        await sut.load()
        
        // Then
        XCTAssertTrue(sut.accounts.isEmpty)
        XCTAssertNotNil(sut.errorMessage)
    }
    
    func testLoad_SetsLoadingState() async {
        // Given
        mockAPIClient.requestDelay = 0.1
        mockAPIClient.mockResponse = [AccountResponseDto]()
        
        // When
        let loadTask = Task {
            await sut.load()
        }
        
        // Then
        try? await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertTrue(sut.isLoading)
        
        await loadTask.value
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Create Tests
    
    func testCreate_Success_ReturnsTrue() async {
        // Given
        let mockResponse = CreateAccountResponseDto(
            id: "new123",
            name: "New Account",
            initialBalance: 100
        )
        mockAPIClient.mockResponse = mockResponse
        
        // When
        let result = await sut.create(
            name: "New Account",
            type: .carteira,
            initialBalance: 100
        )
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockAPIClient.requestCallCount, 1)
        XCTAssertEqual(mockAPIClient.lastPath, "/api/v1/accounts")
        XCTAssertEqual(mockAPIClient.lastMethod, "POST")
        XCTAssertNil(sut.errorMessage)
    }
    
    func testCreate_Failure_ReturnsFalse() async {
        // Given
        mockAPIClient.mockError = APIError.network
        
        // When
        let result = await sut.create(
            name: "New Account",
            type: .carteira,
            initialBalance: 100
        )
        
        // Then
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.errorMessage)
    }
    
    func testCreate_InactiveAccount_SetsInactiveAccountInfo() async {
        // Given
        let problemDetails = ProblemDetails(
            type: nil,
            title: "Conta inativa",
            status: 400,
            detail: "Esta conta está desativada",
            instance: nil,
            errors: nil,
            accountId: "inactive123"
        )
        mockAPIClient.mockError = APIError.server(status: 400, problem: problemDetails)
        
        // When
        let result = await sut.create(
            name: "Inactive",
            type: .carteira,
            initialBalance: 100
        )
        
        // Then
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.inactiveAccount)
        XCTAssertEqual(sut.inactiveAccount?.id, "inactive123")
    }
    
    // MARK: - Update Tests
    
    func testUpdate_Success_ReturnsTrue() async {
        // Given
        let account = AccountResponseDto(
            id: "123",
            name: "Old Name",
            initialBalance: 100,
            accountType: .contaCorrente
        )
        
        // When
        let result = await sut.update(
            account: account,
            name: "New Name",
            type: .contaPoupanca
        )
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockAPIClient.requestNoResponseCallCount, 1)
        XCTAssertEqual(mockAPIClient.lastPath, "/api/v1/accounts/123")
        XCTAssertEqual(mockAPIClient.lastMethod, "PATCH")
        XCTAssertNil(sut.errorMessage)
    }
    
    func testUpdate_Failure_ReturnsFalse() async {
        // Given
        let account = AccountResponseDto(
            id: "123",
            name: "Old Name",
            initialBalance: 100,
            accountType: .contaCorrente
        )
        mockAPIClient.mockError = APIError.network
        
        // When
        let result = await sut.update(
            account: account,
            name: "New Name",
            type: .contaPoupanca
        )
        
        // Then
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.errorMessage)
    }
    
    // MARK: - Delete Tests
    
    func testDelete_Success_RemovesAccount() async {
        // Given
        let mockAccounts = [
            AccountResponseDto(id: "1", name: "Account 1", initialBalance: 100, accountType: .carteira),
            AccountResponseDto(id: "2", name: "Account 2", initialBalance: 200, accountType: .contaCorrente)
        ]
        mockAPIClient.mockResponse = mockAccounts
        await sut.load()
        
        let accountToDelete = mockAccounts[0]
        mockAPIClient.reset()
        
        // When
        await sut.delete(account: accountToDelete)
        
        // Then
        XCTAssertEqual(mockAPIClient.requestNoResponseCallCount, 1)
        XCTAssertEqual(mockAPIClient.lastPath, "/api/v1/accounts/1")
        XCTAssertEqual(mockAPIClient.lastMethod, "DELETE")
        XCTAssertEqual(sut.accounts.count, 1)
        XCTAssertEqual(sut.accounts[0].id, "2")
    }
    
    func testDelete_Failure_SetsErrorMessage() async {
        // Given
        let account = AccountResponseDto(id: "123", name: "Test", initialBalance: 100, accountType: .carteira)
        mockAPIClient.mockError = APIError.network
        
        // When
        await sut.delete(account: account)
        
        // Then
        XCTAssertNotNil(sut.errorMessage)
    }
    
    // MARK: - Reactivate Tests
    
    func testReactivate_Success_ReturnsTrue() async {
        // Given
        let accountId = "inactive123"
        mockAPIClient.mockResponse = [AccountResponseDto]()
        
        // When
        let result = await sut.reactivate(accountId: accountId)
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockAPIClient.requestNoResponseCallCount, 1)
        XCTAssertEqual(mockAPIClient.requestCallCount, 1) // reload after reactivate
        XCTAssertTrue(
            mockAPIClient.requestHistory.contains {
                $0.path == "/api/v1/accounts/inactive123/reactivate" && $0.method == "PATCH"
            }
        )
        XCTAssertTrue(
            mockAPIClient.requestHistory.contains {
                $0.path == "/api/v1/accounts" && $0.method == "GET"
            }
        )
    }
    
    func testReactivate_Failure_ReturnsFalse() async {
        // Given
        mockAPIClient.mockError = APIError.network
        
        // When
        let result = await sut.reactivate(accountId: "inactive123")
        
        // Then
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.errorMessage)
    }
    
    // MARK: - Search Tests
    
    func testApplySearch_FiltersAccountsByName() async {
        // Given
        let mockAccounts = [
            AccountResponseDto(id: "1", name: "Checking Account", initialBalance: 100, accountType: .contaCorrente),
            AccountResponseDto(id: "2", name: "Savings", initialBalance: 200, accountType: .contaPoupanca),
            AccountResponseDto(id: "3", name: "Credit Card", initialBalance: 300, accountType: .carteira)
        ]
        mockAPIClient.mockResponse = mockAccounts
        await sut.load()
        
        // When
        sut.applySearch(term: "Card")
        
        // Then
        XCTAssertEqual(sut.accounts.count, 1)
        XCTAssertEqual(sut.accounts[0].name, "Credit Card")
        XCTAssertEqual(sut.activeSearchTerm, "Card")
    }
    
    func testApplySearch_EmptyTerm_ShowsAllAccounts() async {
        // Given
        let mockAccounts = [
            AccountResponseDto(id: "1", name: "Account 1", initialBalance: 100, accountType: .carteira),
            AccountResponseDto(id: "2", name: "Account 2", initialBalance: 200, accountType: .contaCorrente)
        ]
        mockAPIClient.mockResponse = mockAccounts
        await sut.load()
        sut.applySearch(term: "Account 1")
        
        // When
        sut.applySearch(term: "")
        
        // Then
        XCTAssertEqual(sut.accounts.count, 2)
        XCTAssertTrue(sut.activeSearchTerm.isEmpty)
    }
    
    func testApplySearch_CaseInsensitive() async {
        // Given
        let mockAccounts = [
            AccountResponseDto(id: "1", name: "UPPERCASE", initialBalance: 100, accountType: .carteira),
            AccountResponseDto(id: "2", name: "lowercase", initialBalance: 200, accountType: .contaCorrente)
        ]
        mockAPIClient.mockResponse = mockAccounts
        await sut.load()
        
        // When
        sut.applySearch(term: "upper")
        
        // Then
        XCTAssertEqual(sut.accounts.count, 1)
        XCTAssertEqual(sut.accounts[0].id, "1")
    }
}
