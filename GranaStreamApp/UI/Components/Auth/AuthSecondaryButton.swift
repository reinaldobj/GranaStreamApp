import SwiftUI

struct AuthSecondaryButton: View {
    let title: String
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DS.Typography.section)
                .frame(maxWidth: .infinity, minHeight: DS.Spacing.controlHeight)
        }
        .buttonStyle(AuthSecondaryButtonStyle())
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.6 : 1)
    }
}

private struct AuthSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(DS.Colors.textPrimary)
            .background(
                Capsule()
                    .fill(DS.Colors.surface2)
                    .overlay(
                        Capsule()
                            .stroke(DS.Colors.border, lineWidth: 1)
                    )
            )
    }
}
