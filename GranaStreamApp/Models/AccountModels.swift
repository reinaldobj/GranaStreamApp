import Foundation

struct AccountResponseDto: Codable, Identifiable {
    let id: String
    let name: String?
    let initialBalance: Double
    let accountType: AccountType
}

struct CreateAccountRequestDto: Codable {
    let name: String
    let accountType: AccountType
    let initialBalance: Double
}

struct UpdateAccountRequestDto: Codable {
    let name: String
    let accountType: AccountType
}

struct CreateAccountResponseDto: Codable {
    let id: String
    let name: String?
    let initialBalance: Double
}

struct AccountBalanceDto: Codable, Identifiable {
    let accountId: String
    let accountName: String?
    let balance: Double

    var id: String { accountId }
}

struct AccountsSummaryResponseDto: Codable {
    let totalBalance: Double
    let byAccount: [AccountBalanceDto]?
    let calculatedAt: Date
}
