import SwiftUI

/// View principal de orçamentos por categoria - refatorada em subviews
struct CategoryBudgetsView: View {
    let isPlanningRoot: Bool
    @StateObject private var viewModel = CategoryBudgetsViewModel()
    @EnvironmentObject private var referenceStore: ReferenceDataStore
    @EnvironmentObject private var monthStore: MonthFilterStore
    @Environment(\.dismiss) private var dismiss

    @State private var inputValues: [String: String] = [:]
    @State private var baselineAmounts: [String: String] = [:]
    @State private var hasFinishedInitialLoad = false
    @State private var infoMessage: String?

    init(isPlanningRoot: Bool = false) {
        self.isPlanningRoot = isPlanningRoot
    }

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

                        BudgetListView(
                            items: viewModel.items,
                            isLoading: viewModel.isLoading,
                            hasFinishedInitialLoad: hasFinishedInitialLoad,
                            displayValue: { item in
                                displayValue(for: item)
                            },
                            isEditable: { item in
                                isEditable(item)
                            },
                            isInvalid: { item in
                                isInvalid(categoryId: item.id)
                            },
                            onValueChange: { item, newValue in
                                inputValues[item.id] = newValue
                            },
                            viewportHeight: proxy.size.height
                        )
                        .padding(.top, DS.Spacing.item)
                    }
                }
                .refreshable {
                    await loadData()
                }
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await loadData()
            hasFinishedInitialLoad = true
        }
        .onChange(of: monthStore.selectedMonth) { _, _ in
            Task { await loadData() }
        }
        .onChange(of: viewModel.items) { _, _ in
            syncFormWithLoadedData()
        }
        .errorAlert(message: Binding(
            get: {
                let msg = viewModel.errorMessage
                if msg == "Orçamento não encontrado para esse usuário" {
                    return nil
                }
                return msg
            },
            set: { viewModel.errorMessage = $0 }
        ))
        .alert(
            "Orçamento",
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
        VStack(spacing: DS.Spacing.item) {
            BudgetHeaderView(
                isPlanningRoot: isPlanningRoot,
                monthLabel: monthStore.selectedMonthLabel,
                onDismiss: { dismiss() },
                onMonthShift: { shiftMonth(by: $0) }
            )
            
            BudgetActionsView(
                isSaving: viewModel.isSaving,
                isLoading: viewModel.isLoading,
                hasInvalidValues: hasInvalidValues,
                hasChanges: hasChanges,
                onSave: { Task { await save() } }
            )
        }
        .padding(.horizontal, DS.Spacing.screen)
        .padding(.top, 6)
        .padding(.bottom, 0)
    }

    private var backSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 16, coordinateSpace: .local)
            .onEnded { value in
                guard !isPlanningRoot else { return }
                let fromLeftEdge = value.startLocation.x < 28
                let hasHorizontalIntent = value.translation.width > 80 && abs(value.translation.height) < 60
                guard fromLeftEdge && hasHorizontalIntent else { return }
                dismiss()
            }
    }

    private func loadData() async {
        await referenceStore.loadIfNeeded()
        await viewModel.load(for: monthStore.selectedMonth, categories: referenceStore.categories)
    }

    private func shiftMonth(by value: Int) {
        let calendar = Calendar.current
        guard let updated = calendar.date(byAdding: .month, value: value, to: monthStore.selectedMonth) else { return }
        monthStore.select(month: updated)
    }

    private func syncFormWithLoadedData() {
        var newValues: [String: String] = [:]
        var newBaseline: [String: String] = [:]

        for item in viewModel.items {
            guard isEditable(item) else { continue }
            if let amount = item.amount, let initial = CurrencyTextFieldHelper.initialText(from: amount) {
                newValues[item.id] = initial
                newBaseline[item.id] = initial
            } else {
                newValues[item.id] = ""
            }
        }

        inputValues = newValues
        baselineAmounts = newBaseline
    }

    private func baselineAmount(for categoryId: String) -> Double? {
        if let str = baselineAmounts[categoryId] {
            return CurrencyTextFieldHelper.value(from: str)
        }
        return nil
    }

    private func isInvalid(categoryId: String) -> Bool {
        guard let item = viewModel.items.first(where: { $0.id == categoryId }),
              isEditable(item) else { return false }
        let valueString = inputValues[categoryId, default: ""]
        guard let value = CurrencyTextFieldHelper.value(from: valueString) else { return false }
        return value < 0
    }

    private var hasInvalidValues: Bool {
        viewModel.items.filter(isEditable).contains { isInvalid(categoryId: $0.id) }
    }

    private func amountsAreEqual(_ lhs: Double?, _ rhs: Double?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case let (left?, right?):
            return abs(left - right) < 0.0001
        default:
            return false
        }
    }

    private var pendingChanges: [CategoryBudgetSaveChange] {
        viewModel.items.filter(isEditable).compactMap { item in
            let valueString = inputValues[item.id] ?? ""
            let value = CurrencyTextFieldHelper.value(from: valueString)
            let baseline = baselineAmount(for: item.id)

            if value == nil {
                if amountsAreEqual(nil, baseline) {
                    return nil
                }
                return CategoryBudgetSaveChange(categoryId: item.id, limitAmount: 0)
            }

            guard let parsed = value, parsed >= 0 else {
                return nil
            }

            if amountsAreEqual(parsed, baseline) {
                return nil
            }

            return CategoryBudgetSaveChange(categoryId: item.id, limitAmount: parsed)
        }
    }

    private var hasChanges: Bool {
        !pendingChanges.isEmpty
    }

    private func save() async {
        guard !hasInvalidValues else {
            infoMessage = "Revise os campos com valor inválido antes de salvar."
            return
        }

        let changes = pendingChanges
        guard !changes.isEmpty else {
            infoMessage = "Nenhuma alteração para salvar."
            return
        }

        let result = await viewModel.save(monthStart: monthStore.selectedMonth, changes: changes)

        if !result.savedCategoryIds.isEmpty {
            updateBaselineAfterSave(savedCategoryIds: Set(result.savedCategoryIds))
        }

        if result.failedCount == 0 {
            infoMessage = "\(result.savedCount) categoria(s) salva(s) com sucesso."
            return
        }

        if let firstError = result.firstErrorMessage, !firstError.isEmpty {
            infoMessage = "\(result.savedCount) categoria(s) salvas, \(result.failedCount) com erro.\n\(firstError)"
        } else {
            infoMessage = "\(result.savedCount) categoria(s) salvas, \(result.failedCount) com erro."
        }
    }

    private func updateBaselineAfterSave(savedCategoryIds: Set<String>) {
        for categoryId in savedCategoryIds {
            let valueString = inputValues[categoryId] ?? ""
            if valueString.isEmpty {
                baselineAmounts.removeValue(forKey: categoryId)
            } else {
                baselineAmounts[categoryId] = valueString
            }
        }
    }

    private var parentIdsWithChildren: Set<String> {
        Set(viewModel.items.compactMap(\.parentCategoryId))
    }

    private func isEditable(_ item: CategoryBudgetItem) -> Bool {
        !parentIdsWithChildren.contains(item.id)
    }

    private func displayValue(for item: CategoryBudgetItem) -> String {
        if isEditable(item) {
            return inputValues[item.id] ?? ""
        }

        let total = viewModel.items
            .filter { $0.parentCategoryId == item.id }
            .reduce(0.0) { partial, child in
                partial + (CurrencyTextFieldHelper.value(from: inputValues[child.id] ?? "") ?? 0)
            }

        return CurrencyTextFieldHelper.initialText(from: total) ?? "R$ 0,00"
    }
}

struct CategoryBudgetsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CategoryBudgetsView()
                .preferredColorScheme(.light)

            CategoryBudgetsView()
                .preferredColorScheme(.dark)
        }
        .environmentObject(SessionStore.shared)
        .environmentObject(MonthFilterStore())
        .environmentObject(ReferenceDataStore.shared)
    }
}
