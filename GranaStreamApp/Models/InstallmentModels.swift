import Foundation

struct CreateInstallmentSeriesRequestDto: Codable {
    let description: String?
    let categoryId: String
    let accountDefaultId: String?
    let totalAmount: Double
    let installmentsPlanned: Int
    let firstDueDate: Date
}

struct UpdateInstallmentSeriesRequestDto: Codable {
    let description: String?
    let categoryId: String?
    let accountDefaultId: String?
    let totalAmount: Double?
    let installmentsPlanned: Int?
    let firstDueDate: Date?
}

struct CreateInstallmentSeriesResponseDto: Codable {
    let id: String
}

struct InstallmentItemDto: Codable, Identifiable {
    let installmentNumber: Int
    let dueDate: Date
    let amount: Double
    let status: PayableStatus
    let payableId: String

    var id: String { payableId }
}

struct InstallmentSeriesResponseDto: Codable, Identifiable {
    let id: String
    let userId: String
    let description: String?
    let categoryId: String
    let accountDefaultId: String?
    let totalAmount: Double
    let installmentsPlanned: Int
    let firstDueDate: Date
    let installmentsCreated: Int
    let installmentsSettled: Int
    let amountSettled: Double
    let amountRemaining: Double
    let isActive: Bool
    let installments: [InstallmentItemDto]?
}
