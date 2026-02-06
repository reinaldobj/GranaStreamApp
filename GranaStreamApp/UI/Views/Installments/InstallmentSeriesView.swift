import SwiftUI

struct InstallmentSeriesView: View {
    @StateObject private var viewModel = InstallmentSeriesViewModel()
    @State private var showForm = false
    @State private var selectedSeries: InstallmentSeriesResponseDto?

    var body: some View {
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
                .swipeActions(edge: .leading) {
                    Button {
                        selectedSeries = series
                        showForm = true
                    } label: {
                        Label("Editar", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        Task { await viewModel.delete(id: series.id) }
                    } label: {
                        Label("Excluir", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(DS.Colors.background)
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
