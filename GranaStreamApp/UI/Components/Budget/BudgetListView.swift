import SwiftUI

/// Lista de itens de orçamento
struct BudgetListView: View {
    let items: [CategoryBudgetItem]
    let inputValues: [String: String]
    let isLoading: Bool
    let hasFinishedInitialLoad: Bool
    let isInvalid: (String) -> Bool
    let onValueChange: (String, String) -> Void
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
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    BudgetItemRow(
                        item: item,
                        value: inputValues[item.id] ?? "",
                        isInvalid: isInvalid(item.id),
                        onValueChange: { newValue in
                            onValueChange(item.id, newValue)
                        }
                    )

                    if index < items.count - 1 {
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
