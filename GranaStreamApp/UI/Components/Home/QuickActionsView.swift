import SwiftUI

struct QuickActionsView: View {
    @EnvironmentObject private var referenceStore: ReferenceDataStore
    @State private var showTransactionForm = false

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.item) {
                AppSectionHeader(text: "Atalhos rápidos")
                HStack(spacing: AppTheme.Spacing.item) {
                    QuickActionButton(title: "+ Transação") {
                        Task {
                            await referenceStore.loadIfNeeded()
                            showTransactionForm = true
                        }
                    }
                    NavigationLink {
                        AccountsView()
                    } label: {
                        QuickActionLabel(title: "Nova conta")
                    }
                    .buttonStyle(.plain)

                    NavigationLink {
                        CategoriesView()
                    } label: {
                        QuickActionLabel(title: "Categorias")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .sheet(isPresented: $showTransactionForm) {
            TransactionFormView(existing: nil) { }
        }
    }
}

struct QuickActionLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(AppTheme.Typography.caption)
            .foregroundColor(DS.Colors.primary)
            .frame(maxWidth: .infinity, minHeight: 36)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Radius.field)
                    .stroke(DS.Colors.border, lineWidth: 1)
            )
    }
}

struct QuickActionButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            QuickActionLabel(title: title)
        }
    }
}
