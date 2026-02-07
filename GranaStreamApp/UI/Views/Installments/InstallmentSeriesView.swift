import SwiftUI

struct InstallmentSeriesView: View {
    @StateObject private var viewModel = InstallmentSeriesViewModel()
    @State private var showForm = false
    @State private var selectedSeries: InstallmentSeriesResponseDto?
    @State private var seriesPendingDelete: InstallmentSeriesResponseDto?

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
                                seriesPendingDelete = series
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
        .alert(
            "Excluir parcelamento?",
            isPresented: Binding(
                get: { seriesPendingDelete != nil },
                set: { isPresented in
                    if !isPresented { seriesPendingDelete = nil }
                }
            )
        ) {
            Button("Cancelar", role: .cancel) {
                seriesPendingDelete = nil
            }
            Button("Excluir", role: .destructive) {
                guard let series = seriesPendingDelete else { return }
                seriesPendingDelete = nil
                Task { await viewModel.delete(id: series.id) }
            }
        } message: {
            Text(deleteMessage)
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .errorAlert(message: $viewModel.errorMessage)
        .tint(DS.Colors.primary)
    }

    private var deleteMessage: String {
        let label = seriesPendingDelete?.description?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let label, !label.isEmpty {
            return "Você realmente quer excluir \"\(label)\"?"
        }
        return "Você realmente quer excluir este parcelamento?"
    }
}
