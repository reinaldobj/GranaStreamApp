import SwiftUI

/// Cabeçalho da tela de transações com botões de filtro e adicionar
/// Agora utiliza ListHeaderView genérico
@available(*, deprecated, message: "Use ListHeaderView diretamente")
struct TransactionsHeaderView: View {
    let onShowFilters: () -> Void
    let onAddTransaction: () -> Void
    
    var body: some View {
        ListHeaderView(
            title: L10n.Transactions.title,
            searchText: .constant(""),
            showSearch: false,
            actions: [
                HeaderAction(
                    id: "filter",
                    systemImage: "line.3.horizontal.decrease.circle.fill",
                    action: onShowFilters
                ),
                HeaderAction(
                    id: "add",
                    systemImage: "plus",
                    action: onAddTransaction
                )
            ]
        )
    }
}
