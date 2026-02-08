import SwiftUI

/// Seletor de mês com botões de navegação
struct MonthSelectorView: View {
    @EnvironmentObject private var monthStore: MonthFilterStore
    
    var body: some View {
        HStack(spacing: DS.Spacing.md) {
            monthButton(systemName: "chevron.left", shift: -1)

            Text(monthStore.selectedMonthLabel)
                .font(DS.Typography.section)
                .foregroundColor(DS.Colors.onPrimary)
                .frame(maxWidth: .infinity)

            monthButton(systemName: "chevron.right", shift: 1)
        }
    }
    
    private func monthButton(systemName: String, shift: Int) -> some View {
        Button {
            moveMonth(by: shift)
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: DS.Spacing.iconSmall, height: DS.Spacing.iconSmall)
                .background(DS.Colors.surface.opacity(DS.Opacity.placeholderText))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundColor(DS.Colors.onPrimary)
    }
    
    private func moveMonth(by value: Int) {
        guard let date = Calendar.current.date(byAdding: .month, value: value, to: monthStore.selectedMonth) else {
            return
        }
        monthStore.select(month: date)
    }
}
