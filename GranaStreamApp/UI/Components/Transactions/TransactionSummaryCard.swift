import SwiftUI

struct TransactionSummaryCardLarge: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)

            Text(value)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(DS.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(DS.Colors.surface2)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: DS.Colors.border.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}

struct TransactionSummaryCardSmall: View {
    let title: String
    let value: String
    let icon: String
    let accentColor: Color
    var isSelected: Bool = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(accentColor)
            }

            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)

            Text(value)
                .font(AppTheme.Typography.section)
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
        .shadow(color: DS.Colors.border.opacity(0.2), radius: 6, x: 0, y: 3)
    }
}
