import Foundation

struct RecurrenceTemplateTransactionRequestDto: Codable {
    let type: TransactionType
    let amount: Double
    let description: String?
    let accountId: String?
    let categoryId: String?
}

struct RecurrenceTemplateTransactionDto: Codable {
    let type: TransactionType
    let amount: Double
    let description: String?
    let accountId: String?
    let categoryId: String?
}

struct CreateRecurrenceRequestDto: Codable {
    let templateTransaction: RecurrenceTemplateTransactionRequestDto
    let frequency: RecurrenceFrequency
    let startDate: Date
    let endDate: Date?
    let dayOfMonth: Int?
}

struct UpdateRecurrenceRequestDto: Codable {
    let templateTransaction: RecurrenceTemplateTransactionRequestDto
    let frequency: RecurrenceFrequency
    let startDate: Date?
    let endDate: Date?
    let dayOfMonth: Int?
}

struct CreateRecurrenceResponseDto: Codable {
    let id: String
}

struct RecurrenceResponseDto: Codable, Identifiable {
    let id: String
    let userId: String
    let templateTransaction: RecurrenceTemplateTransactionDto
    let frequency: RecurrenceFrequency
    let startDate: Date
    let endDate: Date?
    let dayOfMonth: Int?
    let dayOfWeek: Int
    let isPaused: Bool
    let nextOccurrence: Date?
}
