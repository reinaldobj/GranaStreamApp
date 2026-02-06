import SwiftUI

struct SecondaryButton: View {
    let title: String
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.section)
                .frame(maxWidth: .infinity, minHeight: AppTheme.Spacing.controlHeight)
        }
        .buttonStyle(SecondaryButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1)
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(DS.Colors.primary)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.button)
                    .stroke(DS.Colors.border, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Radius.button)
                            .fill(configuration.isPressed ? DS.Colors.surface2 : Color.clear)
                    )
            )
    }
}
