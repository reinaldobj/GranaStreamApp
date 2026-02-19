import SwiftUI

struct HomeSummarySectionView: View {
    let totalBalanceText: String
    let totalExpenseText: String
    let budgetSpentText: String
    let budgetLimitText: String
    let budgetProgress: Double
    let budgetProgressText: String

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: DS.Spacing.item) {
                HStack(spacing: DS.Spacing.item) {
                    summaryBlock(
                        title: L10n.Home.totalBalance,
                        value: totalBalanceText,
                        color: DS.Colors.success
                    )

                    Divider()
                        .frame(height: 44)
                        .overlay(DS.Colors.border)

                    summaryBlock(
                        title: L10n.Home.totalExpense,
                        value: totalExpenseText,
                        color: DS.Colors.error
                    )
                }

                VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                    HStack {
                        Text(L10n.Home.budgetUsage)
                            .font(DS.Typography.caption)
                            .foregroundColor(DS.Colors.textSecondary)
                        Spacer()
                        Text(budgetLimitText)
                            .font(DS.Typography.caption.weight(.semibold))
                            .foregroundColor(DS.Colors.textPrimary)
                    }

                    ProgressView(value: budgetProgress)
                        .tint(DS.Colors.primary)

                    Text("\(budgetProgressText) • \(budgetSpentText)")
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                }
            }
        }
    }

    private func summaryBlock(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(DS.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)
            Text(value)
                .font(DS.Typography.body)
                .foregroundColor(color)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    HomeSummarySectionView(
        totalBalanceText: "R$ 7.783,00",
        totalExpenseText: "-R$ 1.187,40",
        budgetSpentText: "R$ 1.187,40",
        budgetLimitText: "R$ 20.000,00",
        budgetProgress: 0.3,
        budgetProgressText: "30%"
    )
    .padding()
}
