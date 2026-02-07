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
    let dayOfWeek: Int?
    let isPaused: Bool
    let nextOccurrence: Date?

    private enum CodingKeys: String, CodingKey {
        case id
        case userId
        case templateTransaction
        case frequency
        case startDate
        case endDate
        case dayOfMonth
        case dayOfWeek
        case isPaused
        case nextOccurrence
    }

    init(
        id: String,
        userId: String,
        templateTransaction: RecurrenceTemplateTransactionDto,
        frequency: RecurrenceFrequency,
        startDate: Date,
        endDate: Date?,
        dayOfMonth: Int?,
        dayOfWeek: Int?,
        isPaused: Bool,
        nextOccurrence: Date?
    ) {
        self.id = id
        self.userId = userId
        self.templateTransaction = templateTransaction
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
        self.dayOfMonth = dayOfMonth
        self.dayOfWeek = dayOfWeek
        self.isPaused = isPaused
        self.nextOccurrence = nextOccurrence
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(String.self, forKey: .id)
        userId = try container.decode(String.self, forKey: .userId)
        templateTransaction = try container.decode(RecurrenceTemplateTransactionDto.self, forKey: .templateTransaction)
        frequency = try container.decode(RecurrenceFrequency.self, forKey: .frequency)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        dayOfMonth = try container.decodeIfPresent(Int.self, forKey: .dayOfMonth)
        dayOfWeek = Self.decodeDayOfWeek(from: container)
        isPaused = try container.decode(Bool.self, forKey: .isPaused)
        nextOccurrence = try container.decodeIfPresent(Date.self, forKey: .nextOccurrence)
    }

    private static func decodeDayOfWeek(from container: KeyedDecodingContainer<CodingKeys>) -> Int? {
        if let intValue = try? container.decodeIfPresent(Int.self, forKey: .dayOfWeek) {
            return intValue
        }

        guard let rawString = (try? container.decodeIfPresent(String.self, forKey: .dayOfWeek)) ?? nil else {
            return nil
        }
        let value = rawString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        switch value {
        case "0", "sunday", "domingo":
            return 0
        case "1", "monday", "segunda", "segunda-feira":
            return 1
        case "2", "tuesday", "terca", "terça", "terça-feira":
            return 2
        case "3", "wednesday", "quarta", "quarta-feira":
            return 3
        case "4", "thursday", "quinta", "quinta-feira":
            return 4
        case "5", "friday", "sexta", "sexta-feira":
            return 5
        case "6", "saturday", "sabado", "sábado":
            return 6
        default:
            return nil
        }
    }
}
