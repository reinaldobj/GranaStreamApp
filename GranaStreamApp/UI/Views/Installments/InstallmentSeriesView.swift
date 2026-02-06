import SwiftUI

struct InstallmentSeriesView: View {
    @StateObject private var viewModel = InstallmentSeriesViewModel()
    @State private var showForm = false
    @State private var selectedSeries: InstallmentSeriesResponseDto?

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.series.isEmpty {
                SkeletonListView()
            } else {
                List {
                    ForEach(viewModel.series) { series in
                        AppCard {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.base) {
                                Text(series.description ?? "Parcelada")
                                    .font(AppTheme.Typography.section)
                                    .foregroundColor(DS.Colors.textPrimary)
                                Text("Restante: \(CurrencyFormatter.string(from: series.amountRemaining))")
                                    .font(AppTheme.Typography.caption)
                                    .foregroundColor(DS.Colors.textSecondary)
                            }
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowBackground(Color.clear)
                        .swipeActions(edge: .trailing) {
                            Button {
                                selectedSeries = series
                                showForm = true
                            } label: {
                                Label("Editar", systemImage: "pencil")
                            }
                            .tint(DS.Colors.primary)
                            Button(role: .destructive) {
                                Task { await viewModel.delete(id: series.id) }
                            } label: {
                                Label("Excluir", systemImage: "trash")
                            }
                            .tint(DS.Colors.error)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(DS.Colors.background)
                .safeAreaInset(edge: .top) {
                    if viewModel.isLoading && !viewModel.series.isEmpty {
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
        .navigationTitle("Parceladas")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    selectedSeries = nil
                    showForm = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showForm) {
            InstallmentSeriesFormView(existing: selectedSeries) {
                Task { await viewModel.load() }
            }
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .errorAlert(message: $viewModel.errorMessage)
        .tint(DS.Colors.primary)
    }
}
