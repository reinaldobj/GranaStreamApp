import SwiftUI

struct AccountCardView: View {
    let account: HomeAccountCardItem

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DS.Colors.primary)
                Text(account.accountType.label)
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
                    .lineLimit(1)
            }

            Text(account.name)
                .font(DS.Typography.body)
                .foregroundColor(DS.Colors.textPrimary)

            Text(CurrencyFormatter.string(from: account.currentBalance))
                .font(DS.Typography.section)
                .foregroundColor(account.currentBalance >= 0 ? DS.Colors.success : DS.Colors.error)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(DS.Spacing.item)
        .frame(width: 180, alignment: .leading)
        .background(DS.Colors.background)
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.field)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.field))
    }

    private var iconName: String {
        switch account.accountType {
        case .carteira:
            return "wallet.pass"
        case .contaCorrente:
            return "building.columns"
        case .contaPoupanca:
            return "banknote"
        }
    }
}
