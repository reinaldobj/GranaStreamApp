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
        taskManager.execute(id: "load") {
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
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: monthStart)
    }

    private func monthStartValue(from monthStart: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: monthStart)
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
        let finalCategories = finalExpenseCategories(from: categories)
        return finalCategories.map { category in
            CategoryBudgetItem(
                categoryId: category.id,
                categoryName: category.name ?? "Categoria",
                parentCategoryName: parentName(for: category, namesById: namesById),
                amount: budgetsByCategory[category.id],
                sortOrder: category.sortOrder
            )
        }
    }

    nonisolated private static func finalExpenseCategories(from categories: [CategoryResponseDto]) -> [CategoryResponseDto] {
        let activeCategories = categories.filter(\.isActive)
        let parentIdsWithChildren = Set(activeCategories.compactMap(\.parentCategoryId))

        return activeCategories
            .filter { $0.categoryType == .expense }
            .filter { category in
                if category.parentCategoryId != nil {
                    return true
                }
                return !parentIdsWithChildren.contains(category.id)
            }
            .sorted { lhs, rhs in
                let lhsParent = lhs.parentCategoryId ?? lhs.id
                let rhsParent = rhs.parentCategoryId ?? rhs.id
                if lhsParent == rhsParent {
                    if lhs.sortOrder == rhs.sortOrder {
                        return (lhs.name ?? "").localizedCaseInsensitiveCompare(rhs.name ?? "") == .orderedAscending
                    }
                    return lhs.sortOrder < rhs.sortOrder
                }

                if lhs.sortOrder == rhs.sortOrder {
                    return (lhs.name ?? "").localizedCaseInsensitiveCompare(rhs.name ?? "") == .orderedAscending
                }
                return lhs.sortOrder < rhs.sortOrder
            }
    }

    nonisolated private static func parentName(for category: CategoryResponseDto, namesById: [String: String]) -> String? {
        guard let parentId = category.parentCategoryId else { return nil }
        return namesById[parentId]
    }
}
