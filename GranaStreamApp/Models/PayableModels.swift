import Foundation

struct PayableListItemDto: Codable, Identifiable {
    let id: String
    let kind: PayableKind
    let status: PayableStatus
    let description: String?
    let amount: Double
    let dueDate: Date
    let accountId: String?
    let categoryId: String?
    let recurrenceId: String?
    let installmentSeriesId: String?
    let installmentNumber: Int?
}

struct ListPayablesResponseDto: Codable {
    let month: String?
    let items: [PayableListItemDto]?
}

struct SettlePayableRequestDto: Codable {
    let accountId: String
    let categoryId: String
    let paidDate: Date
}

struct SettlePayableResponseDto: Codable {
    let payableId: String
    let status: PayableStatus
    let transactionId: String
    let alreadySettled: Bool
}

struct UndoSettlePayableResponseDto: Codable {
    let payableId: String
    let status: PayableStatus
    let transactionId: String?
}
