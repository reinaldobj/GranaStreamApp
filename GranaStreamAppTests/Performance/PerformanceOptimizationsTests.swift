import XCTest
@testable import GranaStreamApp

final class PerformanceOptimizationsTests: XCTestCase {
    func testDateCoderParsingPerformance() {
        let samples = [
            "2026-02-10T12:30:45.1234567Z",
            "2026-02-10T12:30:45.123456Z",
            "2026-02-10T12:30:45.123Z",
            "2026-02-10T12:30:45Z",
            "2026-02-10T12:30:45.1234567"
        ]
        let now = Date()

        measure {
            for _ in 0..<2_000 {
                for sample in samples {
                    _ = DateCoder.parseDate(sample)
                }
                _ = DateCoder.string(from: now)
            }
        }
    }

    func testCategoryGroupingPerformance() {
        let categories = makeCategories(parentCount: 120, childrenPerParent: 4)

        measure {
            _ = groupCategoriesForList(categories)
            _ = groupCategoriesForPicker(categories, transactionType: .expense)
            _ = groupCategoriesForPicker(categories, transactionType: .income)
        }
    }

    func testCurrencyMaskPerformance() {
        let typedInputs = [
            "1",
            "12",
            "123",
            "1234",
            "12345",
            "123456",
            "1234567",
            "12345678",
            "123456789"
        ]

        measure {
            for _ in 0..<1_000 {
                for input in typedInputs {
                    let formatted = CurrencyTextField.formatInput(input)
                    _ = CurrencyTextField.value(from: formatted)
                    _ = CurrencyTextFieldHelper.value(from: formatted)
                }
                _ = CurrencyTextFieldHelper.initialText(from: 9_876.54)
            }
        }
    }

    private func makeCategories(parentCount: Int, childrenPerParent: Int) -> [CategoryResponseDto] {
        var result: [CategoryResponseDto] = []

        for parentIndex in 0..<parentCount {
            let parentId = "parent-\(parentIndex)"
            result.append(
                CategoryResponseDto(
                    id: parentId,
                    name: "Categoria \(parentIndex)",
                    description: nil,
                    categoryType: parentIndex.isMultiple(of: 2) ? .expense : .income,
                    parentCategoryId: nil,
                    parentCategoryName: nil,
                    sortOrder: parentIndex,
                    isActive: true,
                    subCategories: nil
                )
            )

            for childIndex in 0..<childrenPerParent {
                result.append(
                    CategoryResponseDto(
                        id: "child-\(parentIndex)-\(childIndex)",
                        name: "Subcategoria \(parentIndex)-\(childIndex)",
                        description: nil,
                        categoryType: parentIndex.isMultiple(of: 2) ? .expense : .income,
                        parentCategoryId: parentId,
                        parentCategoryName: "Categoria \(parentIndex)",
                        sortOrder: childIndex,
                        isActive: true,
                        subCategories: nil
                    )
                )
            }
        }

        return result
    }
}
