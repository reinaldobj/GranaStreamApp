import Foundation

enum HomePeriod: String, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly
    case yearly

    var id: String { rawValue }

    var apiValue: String {
        switch self {
        case .daily:
            return "day"
        case .weekly:
            return "week"
        case .monthly:
            return "month"
        case .yearly:
            return "year"
        }
    }

    static func fromServerValue(_ value: String?) -> HomePeriod? {
        let normalized = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        switch normalized {
        case "day", "daily", "diario", "diário":
            return .daily
        case "week", "weekly":
            return .weekly
        case "month", "monthly":
            return .monthly
        case "year", "yearly", "annual", "anual":
            return .yearly
        default:
            return nil
        }
    }
}

enum DashboardChartBucket: String {
    case hour
    case day
    case week
    case month
    case year

    static func fromServerValue(_ value: String?) -> DashboardChartBucket {
        let normalized = value?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        switch normalized {
        case "hour", "hours", "hourly":
            return .hour
        case "week", "weekly", "semanal":
            return .week
        case "month", "monthly", "mensal":
            return .month
        case "year", "yearly", "annual", "anual":
            return .year
        default:
            return .day
        }
    }
}

struct DashboardHomeResponseDto: Codable {
    let period: String?
    let range: DashboardRangeResponseDto?
    let summary: DashboardSummaryResponseDto?
    let budget: DashboardBudgetResponseDto?
    let chart: DashboardChartResponseDto?
    let recentTransactions: [DashboardRecentTransactionResponseDto]?
    let meta: DashboardMetaResponseDto?
}

struct DashboardRangeResponseDto: Codable {
    let start: Date
    let end: Date
    let timezone: String?
}

struct DashboardSummaryResponseDto: Codable {
    let totalBalance: Double
    let totalIncome: Double
    let totalExpense: Double
}

struct DashboardBudgetResponseDto: Codable {
    let limitAmount: Double
    let spentAmount: Double
    let remainingAmount: Double
    let utilizationPercent: Double
}

struct DashboardChartResponseDto: Codable {
    let bucket: String?
    let openingBalance: Double
    let points: [DashboardChartPointResponseDto]?

    enum CodingKeys: String, CodingKey {
        case bucket
        case openingBalance
        case points
    }

    init(bucket: String?, openingBalance: Double, points: [DashboardChartPointResponseDto]?) {
        self.bucket = bucket
        self.openingBalance = openingBalance
        self.points = points
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let bucket = try container.decodeIfPresent(String.self, forKey: .bucket)
        let openingBalance = try container.decodeIfPresent(Double.self, forKey: .openingBalance) ?? 0
        let points = try container.decodeIfPresent([DashboardChartPointResponseDto].self, forKey: .points)

        self.bucket = bucket
        self.openingBalance = openingBalance
        self.points = points
    }
}

struct DashboardChartPointResponseDto: Codable, Identifiable {
    let label: String?
    let runningBalance: Double

    enum CodingKeys: String, CodingKey {
        case label
        case runningBalance
        case balance
        case income
        case expense
        case amount
    }

    init(label: String?, runningBalance: Double) {
        self.label = label
        self.runningBalance = runningBalance
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let label = try container.decodeIfPresent(String.self, forKey: .label)
        let runningBalance = try container.decodeIfPresent(Double.self, forKey: .runningBalance)
        let legacyBalance = try container.decodeIfPresent(Double.self, forKey: .balance)
        let amount = try container.decodeIfPresent(Double.self, forKey: .amount)
        let income = try container.decodeIfPresent(Double.self, forKey: .income)
        let expense = try container.decodeIfPresent(Double.self, forKey: .expense)

        self.label = label
        self.runningBalance = runningBalance
            ?? legacyBalance
            ?? amount
            ?? ((income ?? 0) - (expense ?? 0))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(label, forKey: .label)
        try container.encode(runningBalance, forKey: .runningBalance)
    }

    var id: String {
        let base = label?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let base, !base.isEmpty {
            return base
        }
        return "\(runningBalance)"
    }
}

struct DashboardRecentTransactionResponseDto: Codable, Identifiable {
    let id: String
    let date: Date
    let title: String?
    let categoryName: String?
    let type: String?
    let amount: Double

    var resolvedType: TransactionType? {
        let normalized = type?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        switch normalized {
        case "1", "income", "receita":
            return .income
        case "2", "expense", "despesa":
            return .expense
        case "3", "transfer", "transferencia", "transferência":
            return .transfer
        default:
            return nil
        }
    }
}

struct DashboardMetaResponseDto: Codable {
    let recentLimit: Int
    let generatedAt: Date
    let timezone: String?
}

struct HomeAccountCardItem: Identifiable {
    let accountId: String
    let name: String
    let accountType: AccountType
    let initialBalance: Double
    let currentBalance: Double

    var id: String { accountId }
}

// MARK: - Legacy Models
// Mantidos para compatibilidade com componentes antigos que podem continuar no projeto.

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
