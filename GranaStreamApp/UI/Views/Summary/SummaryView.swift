import SwiftUI

struct SummaryView: View {
    @StateObject private var viewModel = SummaryViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.background
                    .ignoresSafeArea()

                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(DS.Colors.primary)
                    } else if let summary = viewModel.summary {
                        ScrollView {
                            VStack(spacing: AppTheme.Spacing.item) {
                                AppCard {
                                    VStack(alignment: .leading, spacing: AppTheme.Spacing.base) {
                                        AppSectionHeader(text: "Total")
                                        Text(CurrencyFormatter.string(from: summary.totalBalance))
                                            .font(AppTheme.Typography.title)
                                            .foregroundColor(DS.Colors.textPrimary)
                                    }
                                }

                                if let accounts = summary.byAccount, !accounts.isEmpty {
                                    AppCard {
                                        VStack(alignment: .leading, spacing: AppTheme.Spacing.item) {
                                            AppSectionHeader(text: "Por conta")
                                            ForEach(Array(accounts.enumerated()), id: \.element.id) { index, item in
                                                HStack {
                                                    Text(item.accountName ?? "Conta")
                                                        .font(AppTheme.Typography.body)
                                                        .foregroundColor(DS.Colors.textPrimary)
                                                    Spacer()
                                                    Text(CurrencyFormatter.string(from: item.balance))
                                                        .font(AppTheme.Typography.body)
                                                        .foregroundColor(DS.Colors.textPrimary)
                                                }
                                                if index < accounts.count - 1 {
                                                    Divider()
                                                        .overlay(DS.Colors.border)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(AppTheme.Spacing.screen)
                        }
                    } else {
                        ContentUnavailableView("Sem dados", systemImage: "tray")
                    }
                }
            }
            .navigationTitle("Resumo")
            .task { await viewModel.load() }
            .errorAlert(message: $viewModel.errorMessage)
        }
        .tint(DS.Colors.primary)
    }
}
