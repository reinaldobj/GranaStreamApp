import SwiftUI

struct AccountAdjustBalanceSheet: View {
    let onConfirm: (Double) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var amountText = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: DS.Spacing.item) {
                Text(L10n.Accounts.Detail.adjustHint)
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)

                VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                    Text(L10n.Accounts.Detail.adjustAmount)
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)

                    CurrencyMaskedTextField(
                        text: $amountText,
                        placeholder: "R$ 0,00"
                    )
                    .frame(height: 48)
                    .padding(.horizontal, DS.Spacing.md)
                    .background(DS.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.field)
                            .stroke(DS.Colors.border, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.field))
                }

                Spacer(minLength: 0)

                AppPrimaryButton(title: L10n.Accounts.Detail.adjustConfirm) {
                    let amount = CurrencyTextFieldHelper.value(from: amountText) ?? 0
                    onConfirm(amount)
                    dismiss()
                }
            }
            .padding(DS.Spacing.screen)
            .navigationTitle(L10n.Accounts.Detail.adjustSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) {
                        dismiss()
                    }
                }
            }
        }
        .tint(DS.Colors.primary)
    }
}

#Preview {
    AccountAdjustBalanceSheet { _ in }
}
