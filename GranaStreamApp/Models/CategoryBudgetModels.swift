import Foundation

struct BudgetResponseDto: Decodable {
    let id: String
    let userId: String
    let categoryId: String
    let limitAmount: Double
    let monthStart: Date
}

struct UpdateBudgetRequestDto: Encodable {
    let categoryId: String
    let limitAmount: Double
    let month: Date
}

struct CategoryBudgetItem: Identifiable, Equatable, Sendable {
    let categoryId: String
    let categoryName: String
    let parentCategoryName: String?
    let amount: Double?
    let sortOrder: Int

    var id: String { categoryId }
}

struct CategoryBudgetSaveChange {
    let categoryId: String
    let limitAmount: Double
}

struct CategoryBudgetSaveResult {
    let savedCount: Int
    let failedCount: Int
    let savedCategoryIds: [String]
    let failedCategoryIds: [String]
    let firstErrorMessage: String?
}
