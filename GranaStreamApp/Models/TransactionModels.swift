import Foundation

struct CreateTransactionRequestDto: Codable {
    let type: TransactionType
    let date: Date
    let amount: Double
    let description: String?
    let accountId: String?
    let categoryId: String?
    let fromAccountId: String?
    let toAccountId: String?
}

struct UpdateTransactionRequestDto: Codable {
    let amount: Double?
    let date: Date?
    let description: String?
    let categoryId: String?
    let fromAccountId: String?
    let toAccountId: String?
}

struct CreateTransactionResponseDto: Codable {
    let id: String
    let message: String?
}

struct PaginationLinksDto: Codable {
    let first: String?
    let previous: String?
    let next: String?
    let last: String?
}

struct TransactionSummaryDto: Codable, Identifiable {
    let id: String
    let type: TransactionType
    let date: Date
    let description: String?
    let amount: Double
    let accountId: String?
    let accountName: String?
    let categoryId: String?
    let categoryName: String?
    let fromAccountId: String?
    let fromAccountName: String?
    let toAccountId: String?
    let toAccountName: String?
    let summary: String?
}

struct TransactionEntryDto: Codable, Identifiable {
    let id: String
    let accountId: String
    let accountName: String?
    let amount: Double
    let flow: FlowType
}

struct TransactionResponseDto: Codable {
    let id: String
    let type: TransactionType
    let date: Date
    let description: String?
    let categoryId: String?
    let categoryName: String?
    let entries: [TransactionEntryDto]?
    let createdAt: Date
}

struct ListTransactionsResponseDto: Codable {
    let items: [TransactionSummaryDto]?
    let page: Int
    let size: Int
    let total: Int
    let links: PaginationLinksDto
}

struct TransactionFilters {
    var startDate: Date
    var endDate: Date
    var type: TransactionType?
    var accountId: String?
    var categoryId: String?
    var searchText: String = ""
}
