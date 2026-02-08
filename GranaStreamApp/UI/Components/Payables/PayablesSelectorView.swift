import SwiftUI

/// Botão de filtro usado em seletores (pendentes/quitados, pagar/receber)
struct PayablesFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.body)
                .foregroundColor(isSelected ? DS.Colors.onPrimary : DS.Colors.onPrimary.opacity(0.7))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? DS.Colors.surface.opacity(0.32) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(DS.Colors.surface.opacity(isSelected ? 0 : 0.28), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
}

/// Bloco de seleção dual (ex: "Pagar | Receber")
struct DualSelectorView: View {
    let title: String
    let firstLabel: String
    let firstSelected: Bool
    let onFirstTap: () -> Void
    let secondLabel: String
    let secondSelected: Bool
    let onSecondTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(DS.Colors.onPrimary.opacity(0.88))

            HStack(spacing: 10) {
                PayablesFilterButton(
                    title: firstLabel,
                    isSelected: firstSelected,
                    action: onFirstTap
                )

                PayablesFilterButton(
                    title: secondLabel,
                    isSelected: secondSelected,
                    action: onSecondTap
                )
            }
        }
    }
}
