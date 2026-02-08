import SwiftUI

/// Cabeçalho da tela de categorias com botões de ação
struct CategoriesHeaderView: View {
    let onDismiss: () -> Void
    let onSeed: () -> Void
    let onAdd: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(DS.Colors.surface.opacity(0.45))
                    .clipShape(Circle())
            }
            .foregroundColor(DS.Colors.onPrimary)

            Spacer()

            Text("Categorias")
                .font(AppTheme.Typography.title)
                .foregroundColor(DS.Colors.onPrimary)

            Spacer()

            HStack(spacing: 10) {
                Button(action: onSeed) {
                    Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .background(DS.Colors.surface.opacity(0.45))
                        .clipShape(Circle())
                }
                .accessibilityLabel("Categorias padrão")

                Button(action: onAdd) {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 40, height: 40)
                        .background(DS.Colors.surface.opacity(0.45))
                        .clipShape(Circle())
                }
            }
            .foregroundColor(DS.Colors.onPrimary)
        }
    }
}
