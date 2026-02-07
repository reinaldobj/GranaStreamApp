import SwiftUI

struct TransactionField<Content: View>: View {
    let label: String
    private let content: Content

    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(AppTheme.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)

            HStack(spacing: 8) {
                content
            }
            .font(AppTheme.Typography.body)
            .foregroundColor(DS.Colors.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: AppTheme.Spacing.controlHeight)
            .background(DS.Colors.surface2)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(DS.Colors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }
}
