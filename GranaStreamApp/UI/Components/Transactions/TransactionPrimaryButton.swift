import SwiftUI

struct TransactionPrimaryButton: View {
    let title: String
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.section)
                .frame(maxWidth: .infinity, minHeight: AppTheme.Spacing.controlHeight)
        }
        .buttonStyle(TransactionPrimaryButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1)
    }
}

private struct TransactionPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(DS.Colors.onPrimary)
            .background(
                Capsule()
                    .fill(DS.Colors.primary.opacity(configuration.isPressed ? 0.9 : 1))
            )
    }
}
