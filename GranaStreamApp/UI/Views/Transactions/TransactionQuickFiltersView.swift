import SwiftUI

/// Atalhos de navegação para outras seções de transações
struct TransactionQuickFiltersView: View {
    private let shortcutColumns = [
        GridItem(.flexible(), spacing: DS.Spacing.item),
        GridItem(.flexible(), spacing: DS.Spacing.item),
        GridItem(.flexible(), spacing: DS.Spacing.item)
    ]

    var body: some View {
        LazyVGrid(columns: shortcutColumns, spacing: DS.Spacing.item) {
            NavigationLink {
                PayablesView()
            } label: {
                payablesShortcut
            }
            .buttonStyle(.plain)

            NavigationLink {
                RecurrencesView()
            } label: {
                recurrencesShortcut
            }
            .buttonStyle(.plain)

            NavigationLink {
                InstallmentSeriesView()
            } label: {
                installmentsShortcut
            }
            .buttonStyle(.plain)
        }
    }

    private var payablesShortcut: some View {
        shortcutButton(systemImage: "checklist")
    }

    private var recurrencesShortcut: some View {
        shortcutButton(systemImage: "arrow.triangle.2.circlepath")
    }

    private var installmentsShortcut: some View {
        shortcutButton(systemImage: "creditcard")
    }

    private func shortcutButton(systemImage: String) -> some View {
        Image(systemName: systemImage)
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(DS.Colors.primary)
            .frame(width: DS.Spacing.iconLarge, height: DS.Spacing.iconLarge)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.field)
                    .fill(DS.Colors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.field)
                    .stroke(DS.Colors.border, lineWidth: 1)
            )
    }
}

#Preview {
    NavigationStack {
        TransactionQuickFiltersView()
            .padding()
    }
}
