import SwiftUI

struct TransactionsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.item) {
                        AppHeaderView()
                        AppCard {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.base) {
                                Text("Lançamentos")
                                    .font(AppTheme.Typography.section)
                                    .foregroundColor(DS.Colors.textPrimary)
                                Text("Em breve você verá suas transações aqui.")
                                    .font(AppTheme.Typography.body)
                                    .foregroundColor(DS.Colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(AppTheme.Spacing.screen)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // TODO: ação futura
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .tint(DS.Colors.primary)
    }
}

#Preview {
    Group {
        TransactionsPlaceholderView()
            .preferredColorScheme(.light)

        TransactionsPlaceholderView()
            .preferredColorScheme(.dark)
    }
    .environmentObject(SessionStore.shared)
    .environmentObject(MonthFilterStore())
}
