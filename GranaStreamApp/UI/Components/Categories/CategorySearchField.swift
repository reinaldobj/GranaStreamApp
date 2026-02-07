import SwiftUI

struct CategorySearchField: View {
    @Binding var text: String
    var onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DS.Colors.textSecondary)

            TextField("Buscar categoria por nome", text: $text)
                .font(AppTheme.Typography.body)
                .foregroundColor(DS.Colors.textPrimary)
                .textInputAutocapitalization(.words)
                .submitLabel(.search)
                .onSubmit(onSubmit)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: AppTheme.Spacing.controlHeight)
        .background(DS.Colors.surface)
        .clipShape(Capsule())
    }
}
