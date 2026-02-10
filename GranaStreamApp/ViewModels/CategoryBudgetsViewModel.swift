import Foundation
import SwiftUI
import Combine

@MainActor
final class CategoryBudgetsViewModel: ObservableObject {
    @Published var items: [CategoryBudgetItem] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    
    private let taskManager = TaskManager()
    private let apiClient: APIClientProtocol
    
    init(apiClient: APIClientProtocol? = nil) {
        self.apiClient = apiClient ?? APIClient.shared
    }

    func load(for monthStart: Date, categories: [CategoryResponseDto]) async {
        await taskManager.executeAndWait(id: "load") {
            self.isLoading = true
            defer { self.isLoading = false }

            self.errorMessage = nil

            let categoryNamesById = Dictionary(uniqueKeysWithValues: categories.map { ($0.id, $0.name ?? "Categoria") })
            let normalizedMonth = self.normalizedMonthStart(from: monthStart)

            var budgetsByCategory: [String: Double] = [:]
            var requestError: Error?

            do {
                let response: [BudgetResponseDto] = try await self.apiClient.request(
                    "/api/v1/budgets",
                    queryItems: [
                        URLQueryItem(name: "month", value: self.monthValue(from: normalizedMonth)),
                        URLQueryItem(name: "monthStart", value: self.monthStartValue(from: normalizedMonth))
                    ]
                )

                budgetsByCategory = Dictionary(uniqueKeysWithValues: response.map { ($0.categoryId, $0.limitAmount) })
            } catch {
                if !self.isNoBudgetForMonthError(error) {
                    requestError = error
                }
            }

            let categoriesSnapshot = categories
            let namesByIdSnapshot = categoryNamesById
            let budgetsByCategorySnapshot = budgetsByCategory
            let items = await Task.detached(priority: .utility) { @Sendable in
                CategoryBudgetBuilder.buildItems(
                    categories: categoriesSnapshot,
                    namesById: namesByIdSnapshot,
                    budgetsByCategory: budgetsByCategorySnapshot
                )
            }.value

            self.items = items

            if let requestError {
                self.errorMessage = requestError.localizedDescription
            }
        }
    }

    func save(monthStart: Date, changes: [CategoryBudgetSaveChange]) async -> CategoryBudgetSaveResult {
        guard !changes.isEmpty else {
            return CategoryBudgetSaveResult(
                savedCount: 0,
                failedCount: 0,
                savedCategoryIds: [],
                failedCategoryIds: [],
                firstErrorMessage: nil
            )
        }

        isSaving = true
        defer { isSaving = false }

        var savedCategoryIds: [String] = []
        var failedCategoryIds: [String] = []
        var firstErrorMessage: String?
        let normalizedMonth = normalizedMonthStart(from: monthStart)

        for change in changes {
            let request = UpdateBudgetRequestDto(
                categoryId: change.categoryId,
                limitAmount: change.limitAmount,
                month: normalizedMonth
            )

            do {
                try await apiClient.requestNoResponse(
                    "/api/v1/budgets",
                    method: "POST",
                    body: AnyEncodable(request)
                )
                savedCategoryIds.append(change.categoryId)
            } catch {
                failedCategoryIds.append(change.categoryId)
                if firstErrorMessage == nil {
                    firstErrorMessage = error.userMessage
                }
            }
        }

        return CategoryBudgetSaveResult(
            savedCount: savedCategoryIds.count,
            failedCount: failedCategoryIds.count,
            savedCategoryIds: savedCategoryIds,
            failedCategoryIds: failedCategoryIds,
            firstErrorMessage: firstErrorMessage
        )
    }

    private func normalizedMonthStart(from monthStart: Date) -> Date {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month], from: monthStart)) ?? monthStart
    }

    private func monthValue(from monthStart: Date) -> String {
        FormatterPool.monthFormatterUTC().string(from: monthStart)
    }

    private func monthStartValue(from monthStart: Date) -> String {
        FormatterPool.monthStartFormatterUTC().string(from: monthStart)
    }

    private func isNoBudgetForMonthError(_ error: Error) -> Bool {
        guard case let APIError.server(status, problem) = error else { return false }

        if status == 404 {
            return true
        }

        if status == 422 {
            let detail = (problem?.detail ?? problem?.title ?? "").lowercased()
            if detail.contains("nenhum orçamento") || detail.contains("no budget") || detail.contains("not found") {
                return true
            }
        }

        return false
    }
}

private enum CategoryBudgetBuilder {
    nonisolated static func buildItems(
        categories: [CategoryResponseDto],
        namesById: [String: String],
        budgetsByCategory: [String: Double]
    ) -> [CategoryBudgetItem] {
        let orderedCategories = orderedExpenseCategories(from: categories)
        return orderedCategories.map { category in
            CategoryBudgetItem(
                categoryId: category.id,
                categoryName: category.name ?? "Categoria",
                parentCategoryId: category.parentCategoryId,
                parentCategoryName: parentName(for: category, namesById: namesById),
                amount: budgetsByCategory[category.id],
                sortOrder: category.sortOrder
            )
        }
    }

    nonisolated private static func orderedExpenseCategories(from categories: [CategoryResponseDto]) -> [CategoryResponseDto] {
        let expenseCategories = categories
            .filter(\.isActive)
            .filter { $0.categoryType == .expense }

        let parents = expenseCategories
            .filter { $0.parentCategoryId == nil }
            .sorted(by: categorySort)

        let parentsById = Dictionary(uniqueKeysWithValues: parents.map { ($0.id, $0) })

        var childrenByParent: [String: [CategoryResponseDto]] = [:]
        var orphanChildren: [CategoryResponseDto] = []

        for child in expenseCategories where child.parentCategoryId != nil {
            guard let parentId = child.parentCategoryId, parentsById[parentId] != nil else {
                orphanChildren.append(child)
                continue
            }
            childrenByParent[parentId, default: []].append(child)
        }

        for key in childrenByParent.keys {
            childrenByParent[key] = (childrenByParent[key] ?? []).sorted(by: categorySort)
        }

        var result: [CategoryResponseDto] = []
        for parent in parents {
            result.append(parent)
            result.append(contentsOf: childrenByParent[parent.id] ?? [])
        }

        if !orphanChildren.isEmpty {
            result.append(contentsOf: orphanChildren.sorted(by: categorySort))
        }

        return result
    }

    nonisolated private static func parentName(for category: CategoryResponseDto, namesById: [String: String]) -> String? {
        guard let parentId = category.parentCategoryId else { return nil }
        return namesById[parentId]
    }

    nonisolated private static func categorySort(lhs: CategoryResponseDto, rhs: CategoryResponseDto) -> Bool {
        if lhs.sortOrder == rhs.sortOrder {
            return (lhs.name ?? "").localizedCaseInsensitiveCompare(rhs.name ?? "") == .orderedAscending
        }
        return lhs.sortOrder < rhs.sortOrder
    }
}
