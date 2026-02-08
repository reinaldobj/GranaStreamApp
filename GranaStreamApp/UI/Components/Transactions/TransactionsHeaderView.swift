import SwiftUI

/// Cabeçalho da tela de transações com botões de filtro e adicionar
struct TransactionsHeaderView: View {
    let onShowFilters: () -> Void
    let onAddTransaction: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onShowFilters) {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(DS.Colors.surface.opacity(0.45))
                    .clipShape(Circle())
            }
            .foregroundColor(DS.Colors.onPrimary)

            Spacer()

            Text("Transações")
                .font(AppTheme.Typography.title)
                .foregroundColor(DS.Colors.onPrimary)

            Spacer()

            Button(action: onAddTransaction) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(DS.Colors.surface.opacity(0.45))
                    .clipShape(Circle())
            }
            .foregroundColor(DS.Colors.onPrimary)
        }
    }
}
