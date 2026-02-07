import SwiftUI

struct PayablesView: View {
    @StateObject private var viewModel = PayablesViewModel()
    @EnvironmentObject private var monthStore: MonthFilterStore
    @EnvironmentObject private var referenceStore: ReferenceDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var selectedKind: PayableKind = .payable
    @State private var selectedStatus: PayablesStatusFilter = .pending
    @State private var selectedPayableForAction: PayableListItemDto?
    @State private var hasFinishedInitialLoad = false
    @State private var infoMessage: String?

    private let sectionSpacing = AppTheme.Spacing.item

    var body: some View {
        GeometryReader { proxy in
            let topBackgroundHeight = max(260, proxy.size.height * 0.36)

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

                        payablesSection(viewportHeight: proxy.size.height)
                            .padding(.top, sectionSpacing)
                    }
                }
                .refreshable {
                    await loadData()
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(item: $selectedPayableForAction) { payable in
            SettlePayableFormView(
                payable: payable,
                actionTitle: actionTitle(for: payable.kind),
                transactionType: transactionType(for: payable.kind)
            ) { request in
                await settle(payable: payable, request: request)
            }
            .environmentObject(referenceStore)
            .presentationDetents([.fraction(0.84)])
            .presentationDragIndicator(.visible)
        }
        .task {
            await referenceStore.loadIfNeeded()
            await loadData()
            hasFinishedInitialLoad = true
        }
        .onChange(of: selectedStatus) { _, _ in
            Task { await loadData() }
        }
        .onChange(of: monthStore.selectedMonth) { _, _ in
            Task { await loadData() }
        }
        .errorAlert(message: $viewModel.errorMessage)
        .alert(
            "Pendências",
            isPresented: Binding(
                get: { infoMessage != nil },
                set: { isPresented in
                    if !isPresented { infoMessage = nil }
                }
            )
        ) {
            Button("OK", role: .cancel) {
                infoMessage = nil
            }
        } message: {
            Text(infoMessage ?? "")
        }
        .tint(DS.Colors.primary)
        .simultaneousGesture(backSwipeGesture)
    }

    private var topBlock: some View {
        VStack(spacing: AppTheme.Spacing.item) {
            header
            monthSelector
            kindSelector
            statusSelector

            if viewModel.isLoading && !viewModel.items.isEmpty {
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

            Text("Pendências")
                .font(AppTheme.Typography.title)
                .foregroundColor(DS.Colors.onPrimary)

            Spacer()

            Color.clear
                .frame(width: 40, height: 40)
        }
    }

    private var monthSelector: some View {
        HStack(spacing: 12) {
            monthButton(systemName: "chevron.left", shift: -1)

            Text(monthStore.selectedMonthLabel)
                .font(AppTheme.Typography.section)
                .foregroundColor(DS.Colors.onPrimary)
                .frame(maxWidth: .infinity)

            monthButton(systemName: "chevron.right", shift: 1)
        }
    }

    private func monthButton(systemName: String, shift: Int) -> some View {
        Button {
            moveMonth(by: shift)
        } label: {
            Image(systemName: systemName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(DS.Colors.onPrimary)
                .frame(width: 32, height: 32)
                .background(DS.Colors.surface.opacity(0.28))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private var kindSelector: some View {
        selectorBlock(
            title: "Tipo",
            firstLabel: PayableKind.payable.label,
            firstSelected: selectedKind == .payable,
            onFirstTap: { selectedKind = .payable },
            secondLabel: PayableKind.receivable.label,
            secondSelected: selectedKind == .receivable,
            onSecondTap: { selectedKind = .receivable }
        )
    }

    private var statusSelector: some View {
        selectorBlock(
            title: "Status",
            firstLabel: PayablesStatusFilter.pending.label,
            firstSelected: selectedStatus == .pending,
            onFirstTap: { selectedStatus = .pending },
            secondLabel: PayablesStatusFilter.settled.label,
            secondSelected: selectedStatus == .settled,
            onSecondTap: { selectedStatus = .settled }
        )
    }

    private func selectorBlock(
        title: String,
        firstLabel: String,
        firstSelected: Bool,
        onFirstTap: @escaping () -> Void,
        secondLabel: String,
        secondSelected: Bool,
        onSecondTap: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppTheme.Typography.caption)
                .foregroundColor(DS.Colors.onPrimary.opacity(0.88))

            HStack(spacing: 10) {
                PayablesFilterButton(
                    title: firstLabel,
                    isSelected: firstSelected,
                    action: onFirstTap
                )

                PayablesFilterButton(
                    title: secondLabel,
                    isSelected: secondSelected,
                    action: onSecondTap
                )
            }
        }
    }

    private func payablesSection(viewportHeight: CGFloat) -> some View {
        let emptyMinHeight = max(320, viewportHeight * 0.52)

        return payablesCard
            .padding(.horizontal, AppTheme.Spacing.screen)
            .padding(.top, 6)
            .frame(
                maxWidth: .infinity,
                minHeight: filteredItems.isEmpty ? emptyMinHeight : nil,
                alignment: .top
            )
            .topSectionStyle()
    }

    private var payablesCard: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            if shouldShowLoadingState {
                loadingState
            } else if filteredItems.isEmpty {
                Text(emptyMessage)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(DS.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                    payableRow(item: item)

                    if index < filteredItems.count - 1 {
                        Divider()
                            .overlay(DS.Colors.border)
                    }
                }
            }
        }
        .padding(.top, 14)
    }

    private func payableRow(item: PayableListItemDto) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.base) {
                HStack(alignment: .top, spacing: 8) {
                    Text(displayDescription(for: item))
                        .font(AppTheme.Typography.section)
                        .foregroundColor(DS.Colors.textPrimary)
                        .lineLimit(2)

                    Spacer(minLength: 8)

                    Text(CurrencyFormatter.string(from: item.amount))
                        .font(AppTheme.Typography.section)
                        .foregroundColor(amountColor(for: item.kind))
                        .multilineTextAlignment(.trailing)
                }

                HStack(spacing: 8) {
                    Text("Vencimento: \(item.dueDate.formattedDate())")
                        .font(AppTheme.Typography.caption)
                        .foregroundColor(DS.Colors.textSecondary)

                    if let origin = originLabel(for: item) {
                        statusBadge(text: origin, color: DS.Colors.accent)
                    }
                }

                HStack {
                    if selectedStatus == .pending && item.status == .pending {
                        Button {
                            selectedPayableForAction = item
                        } label: {
                            Text(viewModel.isSettling(payableId: item.id) ? "Processando..." : actionTitle(for: item.kind))
                                .font(AppTheme.Typography.caption.weight(.semibold))
                                .foregroundColor(DS.Colors.onPrimary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(DS.Colors.primary)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isSettling(payableId: item.id))
                    } else if selectedStatus == .settled && item.status == .settled {
                        Button {
                            Task { await undo(payable: item) }
                        } label: {
                            Text(viewModel.isUndoing(payableId: item.id) ? "Processando..." : "Desfazer")
                                .font(AppTheme.Typography.caption.weight(.semibold))
                                .foregroundColor(DS.Colors.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .stroke(DS.Colors.primary, lineWidth: 1.2)
                                )
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isUndoing(payableId: item.id))
                    } else {
                        statusBadge(text: "Resolvido", color: DS.Colors.success)
                    }

                    Spacer(minLength: 8)
                }
            }
        }
    }

    private func statusBadge(text: String, color: Color) -> some View {
        Text(text)
            .font(AppTheme.Typography.caption.weight(.semibold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(color.opacity(0.12))
            )
    }

    private var shouldShowLoadingState: Bool {
        !hasFinishedInitialLoad || (viewModel.isLoading && viewModel.items.isEmpty)
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(DS.Colors.primary)
            Text("Carregando pendências...")
                .font(AppTheme.Typography.body)
                .foregroundColor(DS.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
    }

    private var filteredItems: [PayableListItemDto] {
        viewModel.items.filter { item in
            item.kind == selectedKind && item.status == selectedStatus.payableStatus
        }
    }

    private var emptyMessage: String {
        switch (selectedKind, selectedStatus) {
        case (.payable, .pending):
            return "Sem pendências para pagar neste mês."
        case (.receivable, .pending):
            return "Sem pendências para receber neste mês."
        case (.payable, .settled):
            return "Sem itens quitados neste mês."
        case (.receivable, .settled):
            return "Sem itens baixados neste mês."
        }
    }

    private func displayDescription(for item: PayableListItemDto) -> String {
        let trimmed = item.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Sem descrição" : trimmed
    }

    private func amountColor(for kind: PayableKind) -> Color {
        switch kind {
        case .payable:
            return DS.Colors.error
        case .receivable:
            return DS.Colors.success
        }
    }

    private func originLabel(for item: PayableListItemDto) -> String? {
        if let installmentNumber = item.installmentNumber {
            return "Parcela \(installmentNumber)"
        }
        if item.installmentSeriesId != nil {
            return "Parcelada"
        }
        if item.recurrenceId != nil {
            return "Recorrência"
        }
        return nil
    }

    private func actionTitle(for kind: PayableKind) -> String {
        switch kind {
        case .payable:
            return "Quitar"
        case .receivable:
            return "Baixar"
        }
    }

    private func transactionType(for kind: PayableKind) -> TransactionType {
        switch kind {
        case .payable:
            return .expense
        case .receivable:
            return .income
        }
    }

    private func moveMonth(by value: Int) {
        guard let date = Calendar.current.date(byAdding: .month, value: value, to: monthStore.selectedMonth) else {
            return
        }
        monthStore.select(month: date)
    }

    private func loadData() async {
        await viewModel.load(month: monthStore.selectedMonth, statusFilter: selectedStatus)
    }

    private func settle(payable: PayableListItemDto, request: SettlePayableRequestDto) async -> Bool {
        guard let response = await viewModel.settle(payableId: payable.id, request: request) else {
            return false
        }

        if response.alreadySettled {
            infoMessage = "Esse item já estava resolvido."
        } else if payable.kind == .payable {
            infoMessage = "Item quitado com sucesso."
        } else {
            infoMessage = "Item baixado com sucesso."
        }

        await loadData()
        return true
    }

    private func undo(payable: PayableListItemDto) async {
        guard let response = await viewModel.undoSettlement(payableId: payable.id) else {
            return
        }

        if response.status == .pending {
            infoMessage = "Quitação desfeita."
        } else {
            infoMessage = "Estado do item atualizado."
        }

        await loadData()
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
}

private struct PayablesFilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.caption.weight(.semibold))
                .foregroundColor(isSelected ? DS.Colors.primary : DS.Colors.onPrimary)
                .frame(maxWidth: .infinity, minHeight: 36)
                .background(
                    Capsule()
                        .fill(isSelected ? DS.Colors.surface : DS.Colors.surface.opacity(0.22))
                )
                .overlay(
                    Capsule()
                        .stroke(DS.Colors.surface.opacity(isSelected ? 0 : 0.28), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

struct PayablesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                PayablesView()
            }
            .preferredColorScheme(.light)

            NavigationStack {
                PayablesView()
            }
            .preferredColorScheme(.dark)
        }
        .environmentObject(MonthFilterStore())
        .environmentObject(ReferenceDataStore.shared)
    }
}
