import SwiftUI

struct TransactionsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.item) {
                        Text("Transações")
                            .font(AppTheme.Typography.title)
                            .foregroundColor(DS.Colors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .center)

                        VStack(alignment: .leading, spacing: AppTheme.Spacing.base) {
                            Text("Lançamentos")
                                .font(AppTheme.Typography.section)
                                .foregroundColor(DS.Colors.textPrimary)
                            Text("Em breve você verá suas transações aqui.")
                                .font(AppTheme.Typography.body)
                                .foregroundColor(DS.Colors.textSecondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(DS.Colors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .shadow(color: DS.Colors.border.opacity(0.25), radius: 10, x: 0, y: 6)
                    }
                    .padding(.horizontal, AppTheme.Spacing.screen)
                    .padding(.top, AppTheme.Spacing.screen + 10)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
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
