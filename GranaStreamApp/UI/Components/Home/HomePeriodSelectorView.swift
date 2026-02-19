import SwiftUI

struct HomePeriodSelectorView: View {
    let selectedPeriod: HomePeriod
    let onSelect: (HomePeriod) -> Void

    var body: some View {
        HStack(spacing: DS.Spacing.sm) {
            periodButton(.daily, label: L10n.Home.Period.daily)
            periodButton(.weekly, label: L10n.Home.Period.weekly)
            periodButton(.monthly, label: L10n.Home.Period.monthly)
            periodButton(.yearly, label: L10n.Home.Period.yearly)
        }
        .padding(6)
        .background(DS.Colors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private func periodButton(_ period: HomePeriod, label: String) -> some View {
        Button {
            onSelect(period)
        } label: {
            Text(label)
                .font(DS.Typography.body)
                .foregroundColor(selectedPeriod == period ? DS.Colors.onPrimary : DS.Colors.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(
                    Capsule()
                        .fill(selectedPeriod == period ? DS.Colors.primary : .clear)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomePeriodSelectorView(selectedPeriod: .monthly) { _ in }
        .padding()
}
