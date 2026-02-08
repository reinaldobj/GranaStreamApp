import SwiftUI

struct AppPrimaryButton: View {
    let title: String
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DS.Typography.section)
                .frame(maxWidth: .infinity, minHeight: DS.Spacing.controlHeight)
        }
        .buttonStyle(AppPrimaryButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1)
    }
}

private struct AppPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(DS.Colors.onPrimary)
            .background(
                Capsule()
                    .fill(DS.Colors.primary.opacity(configuration.isPressed ? 0.9 : 1))
            )
    }
}
