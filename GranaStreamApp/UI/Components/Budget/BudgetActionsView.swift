import SwiftUI

/// Botões de ação da view de orçamentos
struct BudgetActionsView: View {
    let isSaving: Bool
    let isLoading: Bool
    let hasInvalidValues: Bool
    let hasChanges: Bool
    let onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .trailing, spacing: DS.Spacing.xs) {
            HStack(spacing: DS.Spacing.sm) {
                saveButton
                copyButton
            }

            Text("Em breve")
                .font(DS.Typography.caption)
                .foregroundColor(DS.Colors.onPrimary.opacity(DS.Opacity.emphasisText))
        }
    }
    
    private var saveButton: some View {
        Button(action: onSave) {
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: "tray.and.arrow.down")
                Text(isSaving ? "Salvando..." : "Salvar")
            }
            .font(DS.Typography.caption.weight(.semibold))
            .foregroundColor(DS.Colors.onPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.field, style: .continuous)
                    .fill(DS.Colors.surface.opacity(DS.Opacity.selectedState))
            )
        }
        .buttonStyle(.plain)
        .disabled(isSaving || isLoading || hasInvalidValues || !hasChanges)
    }
    
    private var copyButton: some View {
        Button { } label: {
            HStack(spacing: DS.Spacing.xs) {
                Image(systemName: "doc.on.doc")
                Text("Copiar mês anterior")
            }
            .font(DS.Typography.caption.weight(.semibold))
            .foregroundColor(DS.Colors.onPrimary.opacity(DS.Opacity.disabledText))
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.field, style: .continuous)
                    .fill(DS.Colors.surface.opacity(DS.Opacity.backgroundOverlay))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.field, style: .continuous)
                    .stroke(DS.Colors.surface.opacity(DS.Opacity.divider), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(true)
    }
}
