import SwiftUI

/// Botões de ação da view de orçamentos
struct BudgetActionsView: View {
    let isSaving: Bool
    let isLoading: Bool
    let hasInvalidValues: Bool
    let hasChanges: Bool
    let onSave: () -> Void
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 8) {
                saveButton
                copyButton
            }

            Text("Em breve")
                .font(DS.Typography.caption)
                .foregroundColor(DS.Colors.onPrimary.opacity(0.85))
        }
    }
    
    private var saveButton: some View {
        Button(action: onSave) {
            HStack(spacing: 6) {
                Image(systemName: "tray.and.arrow.down")
                Text(isSaving ? "Salvando..." : "Salvar")
            }
            .font(DS.Typography.caption.weight(.semibold))
            .foregroundColor(DS.Colors.onPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(DS.Colors.surface.opacity(0.30))
            )
        }
        .buttonStyle(.plain)
        .disabled(isSaving || isLoading || hasInvalidValues || !hasChanges)
    }
    
    private var copyButton: some View {
        Button { } label: {
            HStack(spacing: 6) {
                Image(systemName: "doc.on.doc")
                Text("Copiar mês anterior")
            }
            .font(DS.Typography.caption.weight(.semibold))
            .foregroundColor(DS.Colors.onPrimary.opacity(0.55))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(DS.Colors.surface.opacity(0.18))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(DS.Colors.surface.opacity(0.25), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(true)
    }
}
