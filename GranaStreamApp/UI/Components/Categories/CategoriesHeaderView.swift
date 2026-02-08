import SwiftUI

/// Cabeçalho da tela de categorias com botões de ação
/// Agora utiliza ListHeaderView genérico
@available(*, deprecated, message: "Use ListHeaderView diretamente")
struct CategoriesHeaderView: View {
    let onDismiss: () -> Void
    let onSeed: () -> Void
    let onAdd: () -> Void
    
    var body: some View {
        ListHeaderView(
            title: L10n.Categories.title,
            searchText: .constant(""),
            showSearch: false,
            actions: [
                HeaderAction(
                    id: "seed",
                    systemImage: "arrow.triangle.2.circlepath.circle.fill",
                    accessibilityLabel: L10n.Categories.seed,
                    action: onSeed
                ),
                HeaderAction(
                    id: "add",
                    systemImage: "plus",
                    action: onAdd
                )
            ],
            onDismiss: onDismiss
        )
    }
}
