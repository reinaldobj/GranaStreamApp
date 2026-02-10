import SwiftUI

/// Seção de lista de transações com paginação
struct TransactionListSection: View {
    let monthSections: [TransactionMonthSection]
    let isLoading: Bool
    let canLoadMore: Bool
    let isLoadingMore: Bool
    let onTransactionTap: (TransactionSummaryDto) -> Void
    let onEdit: (TransactionSummaryDto) -> Void
    let onDelete: (TransactionSummaryDto) -> Void
    let onLoadMore: () -> Void
    let viewportHeight: CGFloat

    var body: some View {
        let emptyMinHeight = max(320, viewportHeight * 0.52)

        return transactionsCard
            .padding(.horizontal, DS.Spacing.screen)
            .padding(.top, DS.Spacing.sm)
            .padding(.bottom, 0)
            .frame(
                maxWidth: .infinity,
                minHeight: monthSections.isEmpty ? emptyMinHeight : nil,
                alignment: .top
            )
            .topSectionStyle()
    }

    private var transactionsCard: some View {
        LazyVStack(alignment: .leading, spacing: DS.Spacing.lg) {
            if shouldShowLoadingState {
                loadingState
            } else if monthSections.isEmpty {
                emptyState
            } else {
                transactionsList
            }
        }
    }

    private var shouldShowLoadingState: Bool {
        isLoading && monthSections.isEmpty
    }

    private var emptyState: some View {
        Text("Sem transações neste período.")
            .font(DS.Typography.body)
            .foregroundColor(DS.Colors.textSecondary)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, DS.Spacing.xxl)
    }

    private var loadingState: some View {
        VStack(spacing: DS.Spacing.md) {
            ProgressView()
                .tint(DS.Colors.primary)
            Text("Carregando lançamentos...")
                .font(DS.Typography.body)
                .foregroundColor(DS.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, DS.Spacing.xxl)
    }

    private var transactionsList: some View {
        let firstMonthId = monthSections.first?.id
        let lastTransactionId = monthSections.last?.items.last?.id

        return VStack(spacing: 0) {
            ForEach(monthSections) { section in
                let lastRowId = section.items.last?.id

                VStack(spacing: 0) {
                    TransactionMonthHeader(title: section.title)
                        .padding(.leading, DS.Spacing.sm)
                        .padding(.top, section.id == firstMonthId ? DS.Spacing.lg : 0)

                    LazyVStack(spacing: DS.Spacing.md) {
                        ForEach(section.items) { transaction in
                            transactionRow(
                                for: transaction,
                                isLastInList: transaction.id == lastTransactionId
                            )

                            if transaction.id != lastRowId {
                                Divider()
                                    .overlay(DS.Colors.border)
                            }
                        }
                    }
                }
            }

            if isLoadingMore {
                loadMoreIndicator
            }
        }
    }

    private func transactionRow(for transaction: TransactionSummaryDto, isLastInList: Bool) -> some View {
        TransactionSwipeRow(
            onTap: { onTransactionTap(transaction) },
            onEdit: { onEdit(transaction) },
            onDelete: { onDelete(transaction) }
        ) {
            TransactionRow(transaction: transaction)
        }
        .contextMenu {
            Button("Editar") {
                onEdit(transaction)
            }
            Button("Excluir", role: .destructive) {
                onDelete(transaction)
            }
        }
        .onAppear {
            guard isLastInList, canLoadMore, !isLoadingMore else { return }
            onLoadMore()
        }
    }

    private var loadMoreIndicator: some View {
        HStack {
            Spacer()
            ProgressView()
                .tint(DS.Colors.primary)
            Spacer()
        }
    }
}

#Preview {
    TransactionListSection(
        monthSections: [],
        isLoading: true,
        canLoadMore: false,
        isLoadingMore: false,
        onTransactionTap: { _ in },
        onEdit: { _ in },
        onDelete: { _ in },
        onLoadMore: {},
        viewportHeight: 800
    )
    .padding()
}
