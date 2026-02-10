import SwiftUI

/// Linha individual de item de orçamento
struct BudgetItemRow: View {
    let item: CategoryBudgetItem
    let value: String
    let isEditable: Bool
    let isInvalid: Bool
    let onValueChange: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.md) {
            categoryInfo
            
            if isEditable {
                CurrencyMaskedTextField(text: .init(
                    get: { value },
                    set: { onValueChange($0) }
                ), placeholder: "R$ 0,00")
                    .keyboardType(.decimalPad)
                    .font(DS.Typography.body)
                    .padding(DS.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.field)
                            .fill(DS.Colors.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.field)
                            .stroke(DS.Colors.border, lineWidth: 1)
                    )
            } else {
                Text(value)
                    .font(DS.Typography.body)
                    .foregroundColor(DS.Colors.textPrimary)
                    .padding(DS.Spacing.sm)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: DS.Radius.field)
                            .fill(DS.Colors.surface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.field)
                            .stroke(DS.Colors.border, lineWidth: 1)
                    )
            }

            if isEditable && isInvalid {
                Text("Digite um valor válido, maior ou igual a zero.")
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.error)
            }
        }
        .padding(.leading, item.parentCategoryId == nil ? 0 : DS.Spacing.item)
    }
    
    private var categoryInfo: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.categoryName)
                    .font(DS.Typography.section)
                    .foregroundColor(DS.Colors.textPrimary)
                    .lineLimit(2)

                if item.parentCategoryId != nil {
                    Text("Categoria filha")
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                } else if !isEditable {
                    Text("Soma das categorias filhas")
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                } else if let parent = item.parentCategoryName?.trimmingCharacters(in: .whitespacesAndNewlines),
                          !parent.isEmpty {
                    Text(parent)
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                }
            }

            Spacer(minLength: 8)
        }
    }
}
