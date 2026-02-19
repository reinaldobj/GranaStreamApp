import SwiftUI

struct AccountDetailView: View {
    @StateObject private var viewModel: AccountDetailViewModel
    @State private var hasLoadedOnce = false
    @State private var showAdjustSheet = false
    @State private var adjustInfoMessage: String?
    @Environment(\.dismiss) private var dismiss

    init(account: HomeAccountCardItem, viewModel: AccountDetailViewModel? = nil) {
        let resolvedViewModel = viewModel ?? AccountDetailViewModel(account: account)
        _viewModel = StateObject(wrappedValue: resolvedViewModel)
    }

    var body: some View {
        ListViewContainer(primaryBackgroundHeight: max(260, UIScreen.main.bounds.height * 0.35)) {
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
        .sheet(isPresented: $showAdjustSheet) {
            AccountAdjustBalanceSheet { amount in
                adjustInfoMessage = viewModel.pendingAdjustBalanceMessage(for: amount)
            }
            .presentationDetents([.fraction(0.42)])
            .presentationDragIndicator(.visible)
        }
        .alert(L10n.Alerts.info, isPresented: Binding(
            get: { adjustInfoMessage != nil },
            set: { shown in
                if !shown { adjustInfoMessage = nil }
            }
        )) {
            Button(L10n.Common.ok, role: .cancel) {
                adjustInfoMessage = nil
            }
        } message: {
            Text(adjustInfoMessage ?? "")
        }
        .errorAlert(message: $viewModel.errorMessage)
        .tint(DS.Colors.primary)
    }

    private var topBlock: some View {
        HStack(spacing: DS.Spacing.item) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DS.Colors.onPrimary)
                    .frame(width: 34, height: 34)
                    .background(DS.Colors.onPrimary.opacity(0.16))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.Accounts.Detail.title)
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.onPrimary.opacity(0.85))
                Text(viewModel.account.name)
                    .font(DS.Typography.section)
                    .foregroundColor(DS.Colors.onPrimary)
                    .lineLimit(1)
            }

            Spacer()
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
                    balanceCard
                    accountInfoCard
                    monthSummaryCard
                    recentTransactionsCard
                }
                .padding(.horizontal, DS.Spacing.screen)
                .padding(.top, DS.Spacing.sm)
            }
        }
        .padding(.bottom, DS.Spacing.sectionSpacing)
        .topSectionStyle()
    }

    private var balanceCard: some View {
        AppCard {
            VStack(spacing: DS.Spacing.item) {
                Text(L10n.Accounts.Detail.currentBalance)
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)

                Text(viewModel.currentBalanceText)
                    .font(DS.Typography.metric)
                    .foregroundColor(DS.Colors.textPrimary)

                AppPrimaryButton(title: L10n.Accounts.Detail.adjust) {
                    showAdjustSheet = true
                }
                .frame(height: 46)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var accountInfoCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: DS.Spacing.item) {
                Text(L10n.Accounts.Detail.accountInfo)
                    .font(DS.Typography.section)
                    .foregroundColor(DS.Colors.textPrimary)

                detailInfoRow(
                    title: L10n.Accounts.Detail.accountType,
                    value: viewModel.account.accountType.label
                )

                Divider().overlay(DS.Colors.border)

                detailInfoRow(
                    title: L10n.Accounts.Detail.initialBalance,
                    value: viewModel.initialBalanceText
                )
            }
        }
    }

    private var monthSummaryCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: DS.Spacing.item) {
                Text(L10n.Accounts.Detail.monthlyOverview)
                    .font(DS.Typography.section)
                    .foregroundColor(DS.Colors.textPrimary)

                HStack(spacing: DS.Spacing.item) {
                    countCard(title: L10n.Accounts.Detail.expenseCount, value: viewModel.expenseCount, color: DS.Colors.error)
                    countCard(title: L10n.Accounts.Detail.incomeCount, value: viewModel.incomeCount, color: DS.Colors.success)
                    countCard(title: L10n.Accounts.Detail.transferCount, value: viewModel.transferCount, color: DS.Colors.textPrimary)
                }
            }
        }
    }

    private var recentTransactionsCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: DS.Spacing.item) {
                Text(L10n.Accounts.Detail.transactionsTitle)
                    .font(DS.Typography.section)
                    .foregroundColor(DS.Colors.textPrimary)

                if viewModel.transactions.isEmpty {
                    Text(L10n.Accounts.Detail.transactionsEmpty)
                        .font(DS.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                } else {
                    VStack(spacing: DS.Spacing.base) {
                        ForEach(viewModel.transactions) { item in
                            AccountDetailTransactionRow(item: item)
                            if item.id != viewModel.transactions.last?.id {
                                Divider().overlay(DS.Colors.border)
                            }
                        }
                    }
                }
            }
        }
    }

    private var loadingState: some View {
        AppCard {
            HStack(spacing: DS.Spacing.sm) {
                ProgressView()
                    .tint(DS.Colors.primary)
                Text(L10n.Accounts.Detail.loading)
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
                    .font(.system(size: 28))
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

    private func detailInfoRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(DS.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(DS.Typography.body)
                .foregroundColor(DS.Colors.textPrimary)
        }
    }

    private func countCard(title: String, value: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(DS.Typography.section)
                .foregroundColor(color)
            Text(title)
                .font(DS.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct AccountDetailTransactionRow: View {
    let item: TransactionSummaryDto

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(displayTitle)
                    .font(DS.Typography.body)
                    .foregroundColor(DS.Colors.textPrimary)
                Text(item.date.formattedDate())
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
            }
            Spacer()
            Text(amountText)
                .font(DS.Typography.body)
                .foregroundColor(amountColor)
                .lineLimit(1)
        }
    }

    private var displayTitle: String {
        let value = (item.description ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? "Sem descrição" : value
    }

    private var amountText: String {
        switch item.type {
        case .income:
            return CurrencyFormatter.string(from: item.amount)
        case .expense:
            return CurrencyFormatter.string(from: -abs(item.amount))
        case .transfer:
            return CurrencyFormatter.string(from: item.amount)
        }
    }

    private var amountColor: Color {
        switch item.type {
        case .income:
            return DS.Colors.success
        case .expense:
            return DS.Colors.error
        case .transfer:
            return DS.Colors.textPrimary
        }
    }
}

#Preview {
    AccountDetailView(
        account: HomeAccountCardItem(
            accountId: "1",
            name: "Carteira",
            accountType: .carteira,
            initialBalance: 0,
            currentBalance: 150
        )
    )
}
