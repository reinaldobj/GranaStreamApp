import SwiftUI

struct AccountRowView: View {
    let account: AccountResponseDto

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(DS.Colors.primary.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(DS.Colors.primary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(account.name ?? "Conta")
                    .font(AppTheme.Typography.section)
                    .foregroundColor(DS.Colors.textPrimary)

                Text(account.accountType.label)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
            }

            Spacer(minLength: 12)

            Text(CurrencyFormatter.string(from: account.initialBalance))
                .font(AppTheme.Typography.section)
                .foregroundColor(DS.Colors.textPrimary)
                .frame(width: 112, alignment: .trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.trailing, 8)
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
