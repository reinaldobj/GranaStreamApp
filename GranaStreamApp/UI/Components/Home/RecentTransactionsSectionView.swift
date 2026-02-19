import SwiftUI

struct RecentTransactionsSectionView: View {
    let transactions: [DashboardRecentTransactionResponseDto]
    let emptyText: String

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: DS.Spacing.item) {
                AppSectionHeader(text: L10n.Home.recentTitle)

                if transactions.isEmpty {
                    Text(emptyText)
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, DS.Spacing.sm)
                } else {
                    VStack(spacing: DS.Spacing.base) {
                        ForEach(transactions.prefix(20)) { item in
                            RecentTransactionRowView(item: item)
                            if item.id != transactions.prefix(20).last?.id {
                                Divider()
                                    .overlay(DS.Colors.border)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct RecentTransactionRowView: View {
    let item: DashboardRecentTransactionResponseDto

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(displayTitle)
                    .font(DS.Typography.body)
                    .foregroundColor(DS.Colors.textPrimary)
                Text("\(item.date.formattedDate()) • \(categoryLabel)")
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
            }
            Spacer()
            Text(amountText)
                .font(DS.Typography.body)
                .foregroundColor(amountColor)
        }
    }

    private var displayTitle: String {
        let trimmed = item.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Sem descrição" : trimmed
    }

    private var categoryLabel: String {
        let trimmed = item.categoryName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Sem categoria" : trimmed
    }

    private var amountText: String {
        switch item.resolvedType {
        case .income:
            return CurrencyFormatter.string(from: item.amount)
        case .expense:
            return CurrencyFormatter.string(from: -abs(item.amount))
        case .transfer, .none:
            return CurrencyFormatter.string(from: item.amount)
        }
    }

    private var amountColor: Color {
        switch item.resolvedType {
        case .income:
            return DS.Colors.success
        case .expense:
            return DS.Colors.error
        case .transfer, .none:
            return DS.Colors.textPrimary
        }
    }
}

#Preview {
    RecentTransactionsSectionView(
        transactions: [
            DashboardRecentTransactionResponseDto(
                id: UUID().uuidString,
                date: Date(),
                title: "Mercado",
                categoryName: "Alimentação",
                type: "expense",
                amount: 120
            ),
            DashboardRecentTransactionResponseDto(
                id: UUID().uuidString,
                date: Date(),
                title: "Salário",
                categoryName: "Trabalho",
                type: "income",
                amount: 5200
            )
        ],
        emptyText: L10n.Home.recentEmpty
    )
    .padding()
}
