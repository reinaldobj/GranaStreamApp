import SwiftUI

/// Cabeçalho da tela de Pendências com botão de voltar
/// Agora utiliza ListHeaderView genérico
@available(*, deprecated, message: "Use ListHeaderView diretamente")
struct PayablesHeaderView: View {
    let onDismiss: () -> Void
    
    var body: some View {
        ListHeaderView(
            title: L10n.Payables.title,
            searchText: .constant(""),
            showSearch: false,
            actions: [],
            onDismiss: onDismiss
        )
    }
}
