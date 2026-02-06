import Foundation

struct AccountSummary: Identifiable {
    let id: UUID
    let name: String
    let balance: Double
}

struct BillItem: Identifiable {
    let id: UUID
    let title: String
    let dueDateText: String
    let amount: Double
}

enum TransactionKind {
    case income
    case expense
}

struct TransactionItem: Identifiable {
    let id: UUID
    let title: String
    let category: String
    let amount: Double
    let kind: TransactionKind
}
