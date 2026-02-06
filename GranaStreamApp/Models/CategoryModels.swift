import Foundation

struct CategoryResponseDto: Codable, Identifiable {
    let id: String
    let name: String?
    let description: String?
    let categoryType: String?
    let parentCategoryId: String?
    let parentCategoryName: String?
    let sortOrder: Int
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date?
    let subCategories: [CategoryResponseDto]?

    var categoryTypeLabel: String {
        if let categoryType, let mapped = CategoryType.fromServerString(categoryType) {
            return mapped.label
        }
        return categoryType ?? "-"
    }
}

struct CreateCategoryRequestDto: Codable {
    let name: String
    let description: String
    let categoryType: CategoryType
    let parentCategoryId: String?
    let sortOrder: Int
}

struct UpdateCategoryRequestDto: Codable {
    let name: String
    let description: String
    let categoryType: CategoryType
    let parentCategoryId: String?
    let sortOrder: Int
}

struct CreateCategoryResponseDto: Codable {
    let id: String
    let name: String?
    let description: String?
    let categoryType: String?
    let parentCategoryId: String?
    let parentCategoryName: String?
    let sortOrder: Int
    let createdAt: Date
}

struct SeedCategoriesResponseDto: Codable {
    let categoriesCreated: Int
    let message: String?
}
