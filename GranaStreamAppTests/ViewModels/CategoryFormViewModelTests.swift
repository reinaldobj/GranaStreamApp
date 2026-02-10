import XCTest
@testable import GranaStreamApp

@MainActor
final class CategoryFormViewModelTests: XCTestCase {
    func testParentOptions_UsesCategoriesFromScreenWhenReferenceStoreIsEmpty() async {
        let mockAPIClient = MockAPIClient()
        let parent = CategoryResponseDto(
            id: "parent-1",
            name: "Moradia",
            description: "",
            categoryType: .expense,
            parentCategoryId: nil,
            parentCategoryName: nil,
            sortOrder: 1,
            isActive: true,
            subCategories: nil
        )
        mockAPIClient.mockResponse = [parent]

        let categoriesViewModel = CategoriesViewModel(apiClient: mockAPIClient)
        await categoriesViewModel.load()

        let referenceStore = ReferenceDataStore(apiClient: mockAPIClient)
        let viewModel = CategoryFormViewModel(
            existing: nil,
            categoriesViewModel: categoriesViewModel,
            referenceStore: referenceStore
        )

        XCTAssertEqual(viewModel.parentOptions.map(\.id), ["parent-1"])
    }

    func testParentOptions_AcceptsEmptyParentIdAsParentCategory() async {
        let mockAPIClient = MockAPIClient()
        let categoriesViewModel = CategoriesViewModel(apiClient: mockAPIClient)
        let referenceStore = ReferenceDataStore(apiClient: mockAPIClient)

        let parentNil = CategoryResponseDto(
            id: "parent-nil",
            name: "Alimentacao",
            description: "",
            categoryType: .expense,
            parentCategoryId: nil,
            parentCategoryName: nil,
            sortOrder: 1,
            isActive: true,
            subCategories: nil
        )
        let parentEmpty = CategoryResponseDto(
            id: "parent-empty",
            name: "Transporte",
            description: "",
            categoryType: .expense,
            parentCategoryId: "",
            parentCategoryName: nil,
            sortOrder: 2,
            isActive: true,
            subCategories: nil
        )
        let child = CategoryResponseDto(
            id: "child-1",
            name: "Uber",
            description: "",
            categoryType: .expense,
            parentCategoryId: "parent-empty",
            parentCategoryName: "Transporte",
            sortOrder: 1,
            isActive: true,
            subCategories: nil
        )
        mockAPIClient.mockResponse = [parentNil, parentEmpty, child]
        await categoriesViewModel.load()

        let viewModel = CategoryFormViewModel(
            existing: nil,
            categoriesViewModel: categoriesViewModel,
            referenceStore: referenceStore
        )

        let parentIds = viewModel.parentOptions.map { $0.id }.sorted()
        XCTAssertEqual(parentIds, ["parent-empty", "parent-nil"])
    }
}
