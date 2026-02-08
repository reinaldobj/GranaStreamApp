import SwiftUI

/// Cabeçalho da view de orçamentos
struct BudgetHeaderView: View {
    let isPlanningRoot: Bool
    let monthLabel: String
    let onDismiss: () -> Void
    let onMonthShift: (Int) -> Void
    
    var body: some View {
        VStack(spacing: DS.Spacing.item) {
            if isPlanningRoot {
                planningMonthSelector
            } else {
                headerWithDismiss
                monthIndicator
            }
        }
    }
    
    private var planningMonthSelector: some View {
        HStack(spacing: DS.Spacing.lg) {
            Button {
                onMonthShift(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: DS.Spacing.iconSmall, height: DS.Spacing.iconSmall)
                    .background(DS.Colors.surface.opacity(DS.Opacity.placeholderText))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundColor(DS.Colors.onPrimary)

            Text(monthLabel)
                .font(DS.Typography.section.weight(.semibold))
                .foregroundColor(DS.Colors.onPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.9)

            Button {
                onMonthShift(1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: DS.Spacing.iconSmall, height: DS.Spacing.iconSmall)
                    .background(DS.Colors.surface.opacity(DS.Opacity.placeholderText))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundColor(DS.Colors.onPrimary)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var headerWithDismiss: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: DS.Spacing.iconMedium, height: DS.Spacing.iconMedium)
                    .background(DS.Colors.surface.opacity(DS.Opacity.medium))
                    .clipShape(Circle())
            }
            .foregroundColor(DS.Colors.onPrimary)

            Spacer()

            Text("Orçamento")
                .font(DS.Typography.title)
                .foregroundColor(DS.Colors.onPrimary)

            Spacer()

            Color.clear
                .frame(width: DS.Spacing.iconMedium, height: DS.Spacing.iconMedium)
        }
    }
    
    private var monthIndicator: some View {
        HStack(spacing: DS.Spacing.sm) {
            Image(systemName: "calendar")
                .foregroundColor(DS.Colors.onPrimary)
            Text(monthLabel)
                .font(DS.Typography.section)
                .foregroundColor(DS.Colors.onPrimary)
            Spacer()
        }
    }
}
