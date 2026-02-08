import SwiftUI

struct AccountRowView: View {
    let account: AccountResponseDto

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.md) {
            ZStack {
                Circle()
                    .fill(DS.Colors.primary.opacity(DS.Opacity.backgroundOverlay))
                    .frame(width: DS.Spacing.iconLarge, height: DS.Spacing.iconLarge)

                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(DS.Colors.primary)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(account.name ?? "Conta")
                    .font(DS.Typography.section)
                    .foregroundColor(DS.Colors.textPrimary)

                Text(account.accountType.label)
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
            }

            Spacer(minLength: DS.Spacing.md)

            Text(CurrencyFormatter.string(from: account.initialBalance))
                .font(DS.Typography.section)
                .foregroundColor(DS.Colors.textPrimary)
                .frame(width: 112, alignment: .trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.trailing, DS.Spacing.sm)
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
