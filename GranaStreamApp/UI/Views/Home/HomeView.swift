import SwiftUI

struct HomeView: View {
    private let accounts: [AccountSummary] = [
        .init(id: UUID(), name: "Carteira", balance: 350.25),
        .init(id: UUID(), name: "Conta Corrente", balance: 1280.10),
        .init(id: UUID(), name: "Poupança", balance: 8420.00),
        .init(id: UUID(), name: "Cartão", balance: -230.45)
    ]

    private let bills: [BillItem] = [
        .init(id: UUID(), title: "Internet", dueDateText: "10/02", amount: 129.90),
        .init(id: UUID(), title: "Energia", dueDateText: "12/02", amount: 210.50),
        .init(id: UUID(), title: "Cartão", dueDateText: "15/02", amount: 589.40)
    ]

    private let transactions: [TransactionItem] = [
        .init(id: UUID(), title: "Salário", category: "Receita", amount: 5200.00, kind: .income),
        .init(id: UUID(), title: "Mercado", category: "Alimentação", amount: 240.30, kind: .expense),
        .init(id: UUID(), title: "Uber", category: "Transporte", amount: 38.90, kind: .expense),
        .init(id: UUID(), title: "Freela", category: "Receita", amount: 800.00, kind: .income),
        .init(id: UUID(), title: "Academia", category: "Saúde", amount: 119.00, kind: .expense)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.item) {
                        AppHeaderView()
                        HomeSummarySectionView()
                        AccountsCarouselView(accounts: accounts)
                        UpcomingBillsSectionView(bills: bills)
                        RecentTransactionsSectionView(transactions: transactions)
                        QuickActionsView()
                    }
                    .padding(AppTheme.Spacing.screen)
                }
            }
        }
        .tint(DS.Colors.primary)
    }
}

#Preview {
    Group {
        HomeView()
            .preferredColorScheme(.light)

        HomeView()
            .preferredColorScheme(.dark)
    }
    .environmentObject(SessionStore.shared)
    .environmentObject(MonthFilterStore())
}
