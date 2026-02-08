import Foundation

struct CategoryResponseDto: Codable, Identifiable {
    let id: String
    let name: String?
    let description: String?
    let categoryType: CategoryType?
    let parentCategoryId: String?
    let parentCategoryName: String?
    let sortOrder: Int
    let isActive: Bool
    let subCategories: [CategoryResponseDto]?

    var categoryTypeLabel: String {
        categoryType?.label ?? "-"
    }
}

struct CreateCategoryRequestDto: Codable {
    let name: String?
    let description: String?
    let categoryType: CategoryType
    let parentCategoryId: String?
    let sortOrder: Int
}

struct UpdateCategoryRequestDto: Codable {
    let name: String?
    let description: String?
    let categoryType: CategoryType
    let parentCategoryId: String?
    let sortOrder: Int
}

struct CreateCategoryResponseDto: Codable {
    let id: String
    let name: String?
    let description: String?
    let categoryType: CategoryType?
    let parentCategoryId: String?
    let parentCategoryName: String?
    let sortOrder: Int
}

struct SeedCategoriesResponseDto: Codable {
    let categoriesCreated: Int
    let message: String?
}
