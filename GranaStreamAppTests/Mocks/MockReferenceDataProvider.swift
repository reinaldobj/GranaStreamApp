import Foundation
import Combine
@testable import GranaStreamApp

// MARK: - Mock Account Provider

@MainActor
final class MockAccountProvider: AccountProvider {
    var accounts: [AccountResponseDto] = []
    
    private(set) var refreshAccountsCalled = false
    private(set) var replaceAccountsCalls: [[AccountResponseDto]] = []
    private(set) var upsertAccountCalls: [AccountResponseDto] = []
    private(set) var removeAccountCalls: [String] = []
    
    func refreshAccounts() async {
        refreshAccountsCalled = true
    }
    
    func replaceAccounts(_ items: [AccountResponseDto]) {
        accounts = items
        replaceAccountsCalls.append(items)
    }
    
    func upsertAccount(_ item: AccountResponseDto) {
        if let index = accounts.firstIndex(where: { $0.id == item.id }) {
            accounts[index] = item
        } else {
            accounts.append(item)
        }
        upsertAccountCalls.append(item)
    }
    
    func removeAccount(id: String) {
        accounts.removeAll { $0.id == id }
        removeAccountCalls.append(id)
    }
}

// MARK: - Mock Category Provider

@MainActor
final class MockCategoryProvider: CategoryProvider {
    var categories: [CategoryResponseDto] = []
    
    private(set) var refreshCategoriesCalled = false
    private(set) var replaceCategoriesCalls: [[CategoryResponseDto]] = []
    private(set) var upsertCategoryCalls: [CategoryResponseDto] = []
    private(set) var removeCategoryCalls: [String] = []
    
    func refreshCategories() async {
        refreshCategoriesCalled = true
    }
    
    func replaceCategories(_ items: [CategoryResponseDto]) {
        categories = items
        replaceCategoriesCalls.append(items)
    }
    
    func upsertCategory(_ item: CategoryResponseDto) {
        if let index = categories.firstIndex(where: { $0.id == item.id }) {
            categories[index] = item
        } else {
            categories.append(item)
        }
        upsertCategoryCalls.append(item)
    }
    
    func removeCategory(id: String) {
        categories.removeAll { $0.id == id }
        removeCategoryCalls.append(id)
    }
}

// MARK: - Mock Observable Reference Data Provider

@MainActor
final class MockObservableReferenceDataProvider: ObservableObject, ObservableReferenceDataProvider {
    let objectWillChange = ObservableObjectPublisher()

    var accounts: [AccountResponseDto] = [] {
        didSet { objectWillChange.send() }
    }
    var categories: [CategoryResponseDto] = [] {
        didSet { objectWillChange.send() }
    }
    
    private(set) var refreshCalled = false
    private(set) var loadIfNeededCalled = false
    private(set) var refreshAccountsCalled = false
    private(set) var refreshCategoriesCalled = false
    
    func refresh() async {
        refreshCalled = true
    }
    
    func loadIfNeeded() async {
        loadIfNeededCalled = true
    }
    
    // AccountProvider
    func refreshAccounts() async {
        refreshAccountsCalled = true
    }
    
    func replaceAccounts(_ items: [AccountResponseDto]) {
        accounts = items
    }
    
    func upsertAccount(_ item: AccountResponseDto) {
        if let index = accounts.firstIndex(where: { $0.id == item.id }) {
            accounts[index] = item
        } else {
            accounts.append(item)
        }
    }
    
    func removeAccount(id: String) {
        accounts.removeAll { $0.id == id }
    }
    
    // CategoryProvider
    func refreshCategories() async {
        refreshCategoriesCalled = true
    }
    
    func replaceCategories(_ items: [CategoryResponseDto]) {
        categories = items
    }
    
    func upsertCategory(_ item: CategoryResponseDto) {
        if let index = categories.firstIndex(where: { $0.id == item.id }) {
            categories[index] = item
        } else {
            categories.append(item)
        }
    }
    
    func removeCategory(id: String) {
        categories.removeAll { $0.id == id }
    }
}

// MARK: - Factory Methods

extension MockObservableReferenceDataProvider {
    /// Cria mock com dados pré-configurados
    static func withData(accounts: [AccountResponseDto], categories: [CategoryResponseDto]) -> MockObservableReferenceDataProvider {
        let mock = MockObservableReferenceDataProvider()
        mock.accounts = accounts
        mock.categories = categories
        return mock
    }
    
    /// Cria mock vazio
    static func empty() -> MockObservableReferenceDataProvider {
        MockObservableReferenceDataProvider()
    }
}
