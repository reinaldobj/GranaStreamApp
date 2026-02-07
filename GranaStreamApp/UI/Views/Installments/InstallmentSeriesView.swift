import SwiftUI

struct InstallmentSeriesView: View {
    @StateObject private var viewModel = InstallmentSeriesViewModel()
    @Environment(\.dismiss) private var dismiss

    @State private var showForm = false
    @State private var selectedSeries: InstallmentSeriesResponseDto?
    @State private var seriesPendingDelete: InstallmentSeriesResponseDto?
    @State private var searchText = ""
    @State private var activeSearchTerm = ""
    @State private var hasFinishedInitialLoad = false

    private let sectionSpacing = AppTheme.Spacing.item

    var body: some View {
        GeometryReader { proxy in
            let topBackgroundHeight = max(240, proxy.size.height * 0.34)

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    DS.Colors.primary
                        .frame(height: topBackgroundHeight)
                        .frame(maxWidth: .infinity)

                    DS.Colors.surface2
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        topBlock
                            .padding(.top, 2)

                        seriesSection(viewportHeight: proxy.size.height)
                            .padding(.top, sectionSpacing)
                    }
                }
                .refreshable {
                    await viewModel.load()
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showForm) {
            InstallmentSeriesFormView(existing: selectedSeries) {
                Task { await viewModel.load() }
            }
            .presentationDetents([.fraction(0.86)])
            .presentationDragIndicator(.visible)
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
        .task {
            await viewModel.load()
            hasFinishedInitialLoad = true
        }
        .onChange(of: searchText) { _, newValue in
            applySearch(term: newValue)
        }
        .errorAlert(message: $viewModel.errorMessage)
        .tint(DS.Colors.primary)
        .simultaneousGesture(backSwipeGesture)
    }

    private var topBlock: some View {
        VStack(spacing: AppTheme.Spacing.item) {
            header
            AppSearchField(
                placeholder: "Buscar parcelada por nome",
                text: $searchText
            ) {
                applySearch(term: searchText)
            }
            if viewModel.isLoading && !viewModel.series.isEmpty {
                HStack {
                    Spacer()
                    LoadingPillView()
                    Spacer()
                }
            }
        }
        .padding(.horizontal, AppTheme.Spacing.screen)
        .padding(.top, 6)
        .padding(.bottom, 0)
    }

    private var header: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(DS.Colors.surface.opacity(0.45))
                    .clipShape(Circle())
            }
            .foregroundColor(DS.Colors.onPrimary)

            Spacer()

            Text("Parceladas")
                .font(AppTheme.Typography.title)
                .foregroundColor(DS.Colors.onPrimary)

            Spacer()

            Button {
                selectedSeries = nil
                showForm = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 40, height: 40)
                    .background(DS.Colors.surface.opacity(0.45))
                    .clipShape(Circle())
            }
            .foregroundColor(DS.Colors.onPrimary)
        }
    }

    private var backSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 16, coordinateSpace: .local)
            .onEnded { value in
                let fromLeftEdge = value.startLocation.x < 28
                let hasHorizontalIntent = value.translation.width > 80 && abs(value.translation.height) < 60
                guard fromLeftEdge && hasHorizontalIntent else { return }
                dismiss()
            }
    }

    private func seriesSection(viewportHeight: CGFloat) -> some View {
        let emptyMinHeight = max(320, viewportHeight * 0.52)

        return seriesCard
            .padding(.horizontal, AppTheme.Spacing.screen)
            .padding(.top, 6)
            .frame(
                maxWidth: .infinity,
                minHeight: filteredSeries.isEmpty ? emptyMinHeight : nil,
                alignment: .top
            )
            .topSectionStyle()
    }

    private var seriesCard: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            if shouldShowLoadingState {
                loadingState
            } else if filteredSeries.isEmpty {
                Text(activeSearchTerm.isEmpty ? "Sem parcelamentos cadastrados." : "Nenhum parcelamento encontrado.")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(DS.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ForEach(Array(filteredSeries.enumerated()), id: \.element.id) { index, series in
                    TransactionSwipeRow(
                        onTap: {},
                        onEdit: {
                            selectedSeries = series
                            showForm = true
                        },
                        onDelete: {
                            seriesPendingDelete = series
                        }
                    ) {
                        rowContent(series: series)
                    }
                    .contextMenu {
                        Button("Editar") {
                            selectedSeries = series
                            showForm = true
                        }
                        Button("Excluir", role: .destructive) {
                            seriesPendingDelete = series
                        }
                    }

                    if index < filteredSeries.count - 1 {
                        Divider()
                            .overlay(DS.Colors.border)
                    }
                }
            }
        }
        .padding(.top, 14)
    }

    private func rowContent(series: InstallmentSeriesResponseDto) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.base) {
                Text(series.description ?? "Parcelada")
                    .font(AppTheme.Typography.section)
                    .foregroundColor(DS.Colors.textPrimary)

                HStack(spacing: 8) {
                    Text("Parcelas: \(series.installmentsSettled)/\(series.installmentsPlanned)")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                    Spacer(minLength: 8)
                    Text("Restante: \(CurrencyFormatter.string(from: series.amountRemaining))")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }

    private var filteredSeries: [InstallmentSeriesResponseDto] {
        let term = activeSearchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return viewModel.series }

        return viewModel.series.filter { series in
            let title = series.description ?? ""
            return title.localizedCaseInsensitiveContains(term)
        }
    }

    private var shouldShowLoadingState: Bool {
        !hasFinishedInitialLoad || (viewModel.isLoading && viewModel.series.isEmpty)
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(DS.Colors.primary)
            Text("Carregando parceladas...")
                .font(AppTheme.Typography.body)
                .foregroundColor(DS.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
    }

    private var deleteMessage: String {
        let label = seriesPendingDelete?.description?.trimmingCharacters(in: .whitespacesAndNewlines)
        if let label, !label.isEmpty {
            return "Você realmente quer excluir \"\(label)\"?"
        }
        return "Você realmente quer excluir este parcelamento?"
    }

    private func applySearch(term: String) {
        activeSearchTerm = term.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
