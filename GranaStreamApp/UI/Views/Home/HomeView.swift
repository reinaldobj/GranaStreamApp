import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var hasLoadedOnce = false

    var body: some View {
        NavigationStack {
            ListViewContainer(primaryBackgroundHeight: max(300, UIScreen.main.bounds.height * 0.45)) {
                VStack(spacing: 0) {
                    topBlock
                        .padding(.horizontal, DS.Spacing.screen)
                        .padding(.top, DS.Spacing.sm)

                    contentBlock
                        .padding(.top, DS.Spacing.item)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                if !hasLoadedOnce {
                    hasLoadedOnce = true
                    await viewModel.load()
                }
            }
            .errorAlert(message: $viewModel.errorMessage)
        }
        .tint(DS.Colors.primary)
    }

    private var topBlock: some View {
        VStack(spacing: DS.Spacing.item) {
            HomeTopHeaderView()

            HomeSummarySectionView(
                totalBalanceText: viewModel.totalBalanceText,
                totalExpenseText: viewModel.totalExpenseText,
                budgetSpentText: viewModel.budgetSpentText,
                budgetLimitText: viewModel.budgetLimitText,
                budgetProgress: viewModel.budgetProgress,
                budgetProgressText: viewModel.budgetProgressText
            )
        }
    }

    private var contentBlock: some View {
        VStack(spacing: DS.Spacing.item) {
            if let message = viewModel.fullScreenErrorMessage {
                errorState(message: message)
                    .padding(.horizontal, DS.Spacing.screen)
                    .padding(.top, DS.Spacing.sm)
            } else if viewModel.hasInitialLoading {
                loadingState
                    .padding(.horizontal, DS.Spacing.screen)
                    .padding(.top, DS.Spacing.sm)
            } else {
                VStack(spacing: DS.Spacing.item) {
                    HomePeriodSelectorView(selectedPeriod: viewModel.selectedPeriod) { period in
                        Task { await viewModel.selectPeriod(period) }
                    }

                    if !viewModel.accountCards.isEmpty {
                        AccountsCarouselView(accounts: viewModel.accountCards)
                    }

                    HomeChartSectionView(
                        points: viewModel.chartPoints,
                        bucket: viewModel.chartBucket,
                        emptyText: L10n.Home.chartEmpty
                    )

                    RecentTransactionsSectionView(
                        transactions: viewModel.recentTransactions,
                        emptyText: L10n.Home.recentEmpty
                    )

                    QuickActionsView()
                }
                .padding(.horizontal, DS.Spacing.screen)
                .padding(.top, DS.Spacing.sm)
            }
        }
        .padding(.bottom, DS.Spacing.sectionSpacing)
        .topSectionStyle()
    }

    private var loadingState: some View {
        AppCard {
            HStack(spacing: DS.Spacing.sm) {
                ProgressView()
                    .tint(DS.Colors.primary)
                Text(L10n.Home.loading)
                    .font(DS.Typography.body)
                    .foregroundColor(DS.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, DS.Spacing.sm)
        }
    }

    private func errorState(message: String) -> some View {
        AppCard {
            VStack(alignment: .center, spacing: DS.Spacing.item) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(DS.Colors.error)

                Text(message)
                    .font(DS.Typography.body)
                    .foregroundColor(DS.Colors.textPrimary)
                    .multilineTextAlignment(.center)

                Button {
                    Task { await viewModel.load() }
                } label: {
                    Text(L10n.Home.retry)
                        .font(DS.Typography.section)
                        .foregroundColor(DS.Colors.onPrimary)
                        .padding(.horizontal, DS.Spacing.lg)
                        .padding(.vertical, DS.Spacing.sm)
                        .background(
                            Capsule()
                                .fill(DS.Colors.primary)
                        )
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HomeView()
                .preferredColorScheme(.light)

            HomeView()
                .preferredColorScheme(.dark)
        }
        .environmentObject(SessionStore.shared)
        .environmentObject(MonthFilterStore())
    }
}
