import SwiftUI

/// Lista de itens de orçamento
struct BudgetListView: View {
    let items: [CategoryBudgetItem]
    let isLoading: Bool
    let hasFinishedInitialLoad: Bool
    let displayValue: (CategoryBudgetItem) -> String
    let isEditable: (CategoryBudgetItem) -> Bool
    let isInvalid: (CategoryBudgetItem) -> Bool
    let onValueChange: (CategoryBudgetItem, String) -> Void
    let viewportHeight: CGFloat
    
    var body: some View {
        let emptyMinHeight = max(320, viewportHeight * 0.52)

        return budgetsCard
            .padding(.horizontal, DS.Spacing.screen)
            .padding(.top, 6)
            .frame(
                maxWidth: .infinity,
                minHeight: items.isEmpty ? emptyMinHeight : nil,
                alignment: .top
            )
            .topSectionStyle()
    }

    private var budgetsCard: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            if shouldShowLoadingState {
                loadingState
            } else if items.isEmpty {
                Text("Sem categorias de despesa para este mês.")
                    .font(DS.Typography.body)
                    .foregroundColor(DS.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                let lastId = items.last?.id

                ForEach(items) { item in
                    BudgetItemRow(
                        item: item,
                        value: displayValue(item),
                        isEditable: isEditable(item),
                        isInvalid: isInvalid(item),
                        onValueChange: { newValue in
                            onValueChange(item, newValue)
                        }
                    )

                    if item.id != lastId {
                        Divider()
                            .overlay(DS.Colors.border)
                    }
                }
            }
        }
        .padding(.top, 14)
    }

    private var shouldShowLoadingState: Bool {
        !hasFinishedInitialLoad || (isLoading && items.isEmpty)
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(DS.Colors.primary)
            Text("Carregando orçamento...")
                .font(DS.Typography.body)
                .foregroundColor(DS.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
    }
}
