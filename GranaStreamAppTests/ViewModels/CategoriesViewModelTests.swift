import XCTest
@testable import GranaStreamApp

@MainActor
final class CategoriesViewModelTests: XCTestCase {
    var sut: CategoriesViewModel!
    var mockAPIClient: MockAPIClient!
    
    override func setUp() async throws {
        mockAPIClient = MockAPIClient()
        sut = CategoriesViewModel(apiClient: mockAPIClient)
    }
    
    override func tearDown() async throws {
        sut = nil
        mockAPIClient = nil
    }
    
    // MARK: - Initialization Tests
    
    func testInit_StartsWithEmptyCategories() {
        XCTAssertTrue(sut.categories.isEmpty)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
        XCTAssertTrue(sut.activeSearchTerm.isEmpty)
    }
    
    // MARK: - Load Tests
    
    func testLoad_Success_UpdatesCategories() async {
        // Given
        let mockCategories = [
            CategoryResponseDto(
                id: "1",
                name: "Food",
                description: "Food expenses",
                categoryType: .expense,
                parentCategoryId: nil,
                parentCategoryName: nil,
                sortOrder: 1,
                isActive: true,
                subCategories: nil
            ),
            CategoryResponseDto(
                id: "2",
                name: "Salary",
                description: "Income",
                categoryType: .income,
                parentCategoryId: nil,
                parentCategoryName: nil,
                sortOrder: 2,
                isActive: true,
                subCategories: nil
            )
        ]
        
        mockAPIClient.mockResponse = mockCategories
        
        // When
        await sut.load()
        
        // Then
        XCTAssertEqual(mockAPIClient.requestCallCount, 1)
        XCTAssertEqual(mockAPIClient.lastPath, "/api/v1/categories")
        XCTAssertEqual(sut.categories.count, 2)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testLoad_SendsIncludeHierarchyFalse() async {
        // Given
        mockAPIClient.mockResponse = [CategoryResponseDto]()
        
        // When
        await sut.load()
        
        // Then
        let queryItems = mockAPIClient.lastQueryItems ?? []
        XCTAssertTrue(queryItems.contains { $0.name == "includeHierarchy" && $0.value == "false" })
    }
    
    func testLoad_Failure_SetsErrorMessage() async {
        // Given
        mockAPIClient.mockError = APIError.network
        
        // When
        await sut.load()
        
        // Then
        XCTAssertTrue(sut.categories.isEmpty)
        XCTAssertNotNil(sut.errorMessage)
    }
    
    // MARK: - Create Tests
    
    func testCreate_Success_ReturnsTrue() async {
        // Given
        let mockResponse = CreateCategoryResponseDto(
            id: "new123",
            name: "New Category",
            description: "Description",
            categoryType: .expense,
            parentCategoryId: nil,
            parentCategoryName: nil,
            sortOrder: 1
        )
        mockAPIClient.mockResponse = mockResponse
        
        // When
        let result = await sut.create(
            name: "New Category",
            description: "Description",
            type: .expense,
            parentId: nil,
            sortOrder: 1
        )
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockAPIClient.requestCallCount, 1)
        XCTAssertEqual(mockAPIClient.lastPath, "/api/v1/categories")
        XCTAssertEqual(mockAPIClient.lastMethod, "POST")
    }
    
    func testCreate_Failure_ReturnsFalse() async {
        // Given
        mockAPIClient.mockError = APIError.network
        
        // When
        let result = await sut.create(
            name: "New Category",
            description: "Description",
            type: .expense,
            parentId: nil,
            sortOrder: 1
        )
        
        // Then
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.errorMessage)
    }
    
    // MARK: - Update Tests
    
    func testUpdate_Success_ReturnsTrue() async {
        // Given
        let category = CategoryResponseDto(
            id: "123",
            name: "Old Name",
            description: "Old Desc",
            categoryType: .expense,
            parentCategoryId: nil,
            parentCategoryName: nil,
            sortOrder: 1,
            isActive: true,
            subCategories: nil
        )
        
        mockAPIClient.mockResponse = category
        
        // When
        let result = await sut.update(
            category: category,
            name: "New Name",
            description: "New Desc",
            type: .income,
            parentId: nil,
            sortOrder: 2
        )
        
        // Then
        XCTAssertTrue(result)
        XCTAssertEqual(mockAPIClient.requestCallCount, 1)
        XCTAssertEqual(mockAPIClient.lastPath, "/api/v1/categories/123")
        XCTAssertEqual(mockAPIClient.lastMethod, "PUT")
    }
    
    func testUpdate_Failure_ReturnsFalse() async {
        // Given
        let category = CategoryResponseDto(
            id: "123",
            name: "Test",
            description: "Desc",
            categoryType: .expense,
            parentCategoryId: nil,
            parentCategoryName: nil,
            sortOrder: 1,
            isActive: true,
            subCategories: nil
        )
        mockAPIClient.mockError = APIError.network
        
        // When
        let result = await sut.update(
            category: category,
            name: "New Name",
            description: "New Desc",
            type: .income,
            parentId: nil,
            sortOrder: 2
        )
        
        // Then
        XCTAssertFalse(result)
        XCTAssertNotNil(sut.errorMessage)
    }
    
    // MARK: - Delete Tests
    
    func testDelete_Success_RemovesCategory() async {
        // Given
        let mockCategories = [
            CategoryResponseDto(id: "1", name: "Cat 1", description: "", categoryType: .expense,
                              parentCategoryId: nil, parentCategoryName: nil, sortOrder: 1, isActive: true, subCategories: nil),
            CategoryResponseDto(id: "2", name: "Cat 2", description: "", categoryType: .expense,
                              parentCategoryId: nil, parentCategoryName: nil, sortOrder: 2, isActive: true, subCategories: nil)
        ]
        mockAPIClient.mockResponse = mockCategories
        await sut.load()
        
        let categoryToDelete = mockCategories[0]
        mockAPIClient.reset()
        
        // When
        await sut.delete(category: categoryToDelete)
        
        // Then
        XCTAssertEqual(mockAPIClient.requestNoResponseCallCount, 1)
        XCTAssertEqual(mockAPIClient.lastPath, "/api/v1/categories/1")
        XCTAssertEqual(mockAPIClient.lastMethod, "DELETE")
        XCTAssertEqual(sut.categories.count, 1)
        XCTAssertEqual(sut.categories[0].id, "2")
    }
    
    func testDelete_Failure_SetsErrorMessage() async {
        // Given
        let category = CategoryResponseDto(
            id: "123", name: "Test", description: "", categoryType: .expense,
            parentCategoryId: nil, parentCategoryName: nil, sortOrder: 1, isActive: true, subCategories: nil
        )
        mockAPIClient.mockError = APIError.network
        
        // When
        await sut.delete(category: category)
        
        // Then
        XCTAssertNotNil(sut.errorMessage)
    }
    
    // MARK: - Seed Tests
    
    func testSeed_Success_ReloadsCategories() async {
        // Given
        let seedResponse = SeedCategoriesResponseDto(categoriesCreated: 10, message: "Seeded")
        mockAPIClient.mockResponse = seedResponse
        
        // When
        await sut.seed()
        
        // Then
        XCTAssertEqual(mockAPIClient.requestCallCount, 2) // seed + load
        XCTAssertTrue(mockAPIClient.requestHistory.contains { $0.path == "/api/v1/categories/seed" && $0.method == "POST" })
    }
    
    // MARK: - Search Tests
    
    func testApplySearch_FiltersCategories() async {
        // Given
        let mockCategories = [
            CategoryResponseDto(id: "1", name: "Food", description: "", categoryType: .expense,
                              parentCategoryId: nil, parentCategoryName: nil, sortOrder: 1, isActive: true, subCategories: nil),
            CategoryResponseDto(id: "2", name: "Transport", description: "", categoryType: .expense,
                              parentCategoryId: nil, parentCategoryName: nil, sortOrder: 2, isActive: true, subCategories: nil),
            CategoryResponseDto(id: "3", name: "Salary", description: "", categoryType: .income,
                              parentCategoryId: nil, parentCategoryName: nil, sortOrder: 3, isActive: true, subCategories: nil)
        ]
        mockAPIClient.mockResponse = mockCategories
        await sut.load()
        
        // When
        sut.applySearch(term: "Food")
        
        // Then
        XCTAssertEqual(sut.categories.count, 1)
        XCTAssertEqual(sut.categories[0].name, "Food")
        XCTAssertEqual(sut.activeSearchTerm, "Food")
    }
    
    func testApplySearch_EmptyTerm_ShowsAll() async {
        // Given
        let mockCategories = [
            CategoryResponseDto(id: "1", name: "Cat 1", description: "", categoryType: .expense,
                              parentCategoryId: nil, parentCategoryName: nil, sortOrder: 1, isActive: true, subCategories: nil),
            CategoryResponseDto(id: "2", name: "Cat 2", description: "", categoryType: .expense,
                              parentCategoryId: nil, parentCategoryName: nil, sortOrder: 2, isActive: true, subCategories: nil)
        ]
        mockAPIClient.mockResponse = mockCategories
        await sut.load()
        sut.applySearch(term: "Cat 1")
        
        // When
        sut.applySearch(term: "")
        
        // Then
        XCTAssertEqual(sut.categories.count, 2)
        XCTAssertTrue(sut.activeSearchTerm.isEmpty)
    }
    
    func testApplySearch_IncludesParentWhenChildMatches() async {
        // Given
        let parent = CategoryResponseDto(id: "parent", name: "Parent", description: "", categoryType: .expense,
                                        parentCategoryId: nil, parentCategoryName: nil, sortOrder: 1, isActive: true, subCategories: nil)
        let child = CategoryResponseDto(id: "child", name: "Child Category", description: "", categoryType: .expense,
                                       parentCategoryId: "parent", parentCategoryName: "Parent", sortOrder: 1, isActive: true, subCategories: nil)
        
        mockAPIClient.mockResponse = [parent, child]
        await sut.load()
        
        // When
        sut.applySearch(term: "Child")
        
        // Then - should include both parent and child
        XCTAssertEqual(sut.categories.count, 2)
        XCTAssertTrue(sut.categories.contains { $0.id == "parent" })
        XCTAssertTrue(sut.categories.contains { $0.id == "child" })
    }
}
