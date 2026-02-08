import SwiftUI

/// Botão de filtro usado em seletores (pendentes/quitados, pagar/receber)
struct PayablesFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DS.Typography.body)
                .foregroundColor(isSelected ? DS.Colors.onPrimary : DS.Colors.onPrimary.opacity(DS.Opacity.secondaryText))
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.field)
                        .fill(isSelected ? DS.Colors.surface.opacity(DS.Opacity.buttonHover) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.field)
                                .strokeBorder(DS.Colors.surface.opacity(isSelected ? 0 : DS.Opacity.placeholderText), lineWidth: 1)
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
        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
            Text(title)
                .font(DS.Typography.caption)
                .foregroundColor(DS.Colors.onPrimary.opacity(DS.Opacity.emphasisTextStrong))

            HStack(spacing: DS.Spacing.md) {
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
