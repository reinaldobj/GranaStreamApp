import SwiftUI

struct TransactionSummaryCardLarge: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: DS.Spacing.xs) {
            Text(title)
                .font(DS.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)

            Text(value)
                .font(DS.Typography.metric)
                .foregroundColor(DS.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(DS.Spacing.lg)
        .background(DS.Colors.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: DS.Colors.border.opacity(DS.Opacity.divider), radius: 8, x: 0, y: 4)
    }
}

struct TransactionSummaryCardSmall: View {
    let title: String
    let value: String
    let icon: String
    let accentColor: Color
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: DS.Spacing.xs) {
            ZStack {
                RoundedRectangle(cornerRadius: DS.Radius.field, style: .continuous)
                    .fill(accentColor.opacity(DS.Opacity.backgroundOverlay))
                    .frame(width: DS.Spacing.iconMedium, height: DS.Spacing.iconMedium)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(accentColor)
            }

            Text(title)
                .font(DS.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)

            Text(value)
                .font(DS.Typography.section)
                .foregroundColor(DS.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(DS.Colors.surface2)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(isSelected ? accentColor : DS.Colors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: DS.Colors.border.opacity(DS.Opacity.subtle), radius: 6, x: 0, y: 3)
    }
}
