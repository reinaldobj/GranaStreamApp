import SwiftUI

struct TransactionsView: View {
    @StateObject private var viewModel = TransactionsViewModel()
    @EnvironmentObject private var referenceStore: ReferenceDataStore

    @State private var showForm = false
    @State private var selectedTransactionForDetail: TransactionSummaryDto?
    @State private var selectedTransactionForEdit: TransactionSummaryDto?
    @State private var showFilters = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.transactions.isEmpty {
                    SkeletonListView()
                } else {
                    List {
                        ForEach(viewModel.transactions) { transaction in
                            Button {
                                selectedTransactionForDetail = transaction
                            } label: {
                                AppCard {
                                    TransactionRow(transaction: transaction)
                                }
                            }
                            .buttonStyle(.plain)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing) {
                                Button {
                                    selectedTransactionForEdit = transaction
                                    showForm = true
                                } label: {
                                    Label("Editar", systemImage: "pencil")
                                }
                                .tint(DS.Colors.primary)
                                Button(role: .destructive) {
                                    Task { await viewModel.delete(transaction: transaction) }
                                } label: {
                                    Label("Excluir", systemImage: "trash")
                                }
                                .tint(DS.Colors.error)
                            }
                        }

                        if viewModel.canLoadMore {
                            HStack {
                                Spacer()
                                if viewModel.isLoadingMore {
                                    ProgressView()
                                        .tint(DS.Colors.primary)
                                }
                                Spacer()
                            }
                            .task { await viewModel.loadMore() }
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(DS.Colors.background)
                    .safeAreaInset(edge: .top) {
                        if viewModel.isLoading && !viewModel.transactions.isEmpty {
                            HStack {
                                Spacer()
                                LoadingPillView()
                                Spacer()
                            }
                            .padding(.top, 6)
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showFilters = true
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        selectedTransactionForEdit = nil
                        showForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showForm) {
                TransactionFormView(existing: selectedTransactionForEdit) {
                    Task { await viewModel.load(reset: true) }
                }
            }
            .sheet(isPresented: $showFilters) {
                TransactionFiltersView(filters: $viewModel.filters) {
                    Task { await viewModel.load(reset: true) }
                }
            }
            .sheet(item: $selectedTransactionForDetail) { item in
                TransactionDetailView(transaction: item)
            }
            .task {
                await referenceStore.loadIfNeeded()
                await viewModel.load(reset: true)
            }
            .refreshable {
                await viewModel.load(reset: true)
            }
            .errorAlert(message: $viewModel.errorMessage)
        }
        .tint(DS.Colors.primary)
    }
}
