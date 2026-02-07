import SwiftUI

// TODO: [TECH-DEBT] View gigante com 587 linhas - Extrair CurrencyMaskedTextField para UI/Components/
// TODO: [TECH-DEBT] Considerar dividir em subviews: BudgetHeaderView, BudgetListView, BudgetItemRow
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

    private let sectionSpacing = AppTheme.Spacing.item

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

                        budgetsSection(viewportHeight: proxy.size.height)
                            .padding(.top, sectionSpacing)
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
        VStack(spacing: AppTheme.Spacing.item) {
            if isPlanningRoot {
                planningMonthSelector
            } else {
                header
                monthIndicator
            }
            actionsBlock
        }
        .padding(.horizontal, AppTheme.Spacing.screen)
        .padding(.top, 6)
        .padding(.bottom, 0)
    }

    private var planningMonthSelector: some View {
        HStack(spacing: 14) {
            Button {
                shiftMonth(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(DS.Colors.surface.opacity(0.28))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundColor(DS.Colors.onPrimary)

            Text(monthStore.selectedMonthLabel)
                .font(AppTheme.Typography.section.weight(.semibold))
                .foregroundColor(DS.Colors.onPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.9)

            Button {
                shiftMonth(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(DS.Colors.surface.opacity(0.28))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundColor(DS.Colors.onPrimary)
        }
        .frame(maxWidth: .infinity)
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

            Text("Orçamento")
                .font(AppTheme.Typography.title)
                .foregroundColor(DS.Colors.onPrimary)

            Spacer()

            Color.clear
                .frame(width: 40, height: 40)
        }
    }

    private var monthIndicator: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar")
                .foregroundColor(DS.Colors.onPrimary)
            Text(monthStore.selectedMonthLabel)
                .font(AppTheme.Typography.section)
                .foregroundColor(DS.Colors.onPrimary)
            Spacer()
        }
    }

    private var actionsBlock: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(spacing: 8) {
                Button {
                    Task { await save() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "tray.and.arrow.down")
                        Text(viewModel.isSaving ? "Salvando..." : "Salvar")
                    }
                    .font(AppTheme.Typography.caption.weight(.semibold))
                    .foregroundColor(DS.Colors.onPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(DS.Colors.surface.opacity(0.30))
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isSaving || viewModel.isLoading || hasInvalidValues || !hasChanges)

                Button { } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                        Text("Copiar mês anterior")
                    }
                    .font(AppTheme.Typography.caption.weight(.semibold))
                    .foregroundColor(DS.Colors.onPrimary.opacity(0.55))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(DS.Colors.surface.opacity(0.18))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(DS.Colors.surface.opacity(0.25), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .disabled(true)
            }

            Text("Em breve")
                .font(AppTheme.Typography.caption)
                .foregroundColor(DS.Colors.onPrimary.opacity(0.85))
        }
    }

    private func budgetsSection(viewportHeight: CGFloat) -> some View {
        let emptyMinHeight = max(320, viewportHeight * 0.52)

        return budgetsCard
            .padding(.horizontal, AppTheme.Spacing.screen)
            .padding(.top, 6)
            .frame(
                maxWidth: .infinity,
                minHeight: viewModel.items.isEmpty ? emptyMinHeight : nil,
                alignment: .top
            )
            .topSectionStyle()
    }

    private var budgetsCard: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            if shouldShowLoadingState {
                loadingState
            } else if viewModel.items.isEmpty {
                Text("Sem categorias de despesa para este mês.")
                    .font(AppTheme.Typography.body)
                    .foregroundColor(DS.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 24)
            } else {
                ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                    budgetRow(item: item)

                    if index < viewModel.items.count - 1 {
                        Divider()
                            .overlay(DS.Colors.border)
                    }
                }
            }
        }
        .padding(.top, 14)
    }

    private func budgetRow(item: CategoryBudgetItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.categoryName)
                        .font(AppTheme.Typography.section)
                        .foregroundColor(DS.Colors.textPrimary)
                        .lineLimit(2)

                    if let parent = item.parentCategoryName?.trimmingCharacters(in: .whitespacesAndNewlines),
                       !parent.isEmpty {
                        Text(parent)
                            .font(AppTheme.Typography.caption)
                            .foregroundColor(DS.Colors.textSecondary)
                    }
                }

                Spacer(minLength: 8)
            }

            CurrencyMaskedTextField(text: binding(for: item.id), placeholder: "R$ 0,00")
                .keyboardType(.decimalPad)
                .font(AppTheme.Typography.body)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(DS.Colors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(DS.Colors.border, lineWidth: 1)
                )

            if isInvalid(categoryId: item.id) {
                Text("Digite um valor válido, maior ou igual a zero.")
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(DS.Colors.error)
            }
        }
    }

    private var shouldShowLoadingState: Bool {
        !hasFinishedInitialLoad || (viewModel.isLoading && viewModel.items.isEmpty)
    }

    private var loadingState: some View {
        VStack(spacing: 12) {
            ProgressView()
                .tint(DS.Colors.primary)
            Text("Carregando orçamento...")
                .font(AppTheme.Typography.body)
                .foregroundColor(DS.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.vertical, 24)
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

    private func binding(for categoryId: String) -> Binding<String> {
        Binding(
            get: { inputValues[categoryId, default: ""] },
            set: { inputValues[categoryId] = $0 }
        )
    }

    private func baselineAmount(for categoryId: String) -> Double? {
        if let str = baselineAmounts[categoryId] {
            return CurrencyTextFieldHelper.value(from: str)
        }
        return nil
    }

    private func isInvalid(categoryId: String) -> Bool {
        let valueString = inputValues[categoryId, default: ""]
        guard let value = CurrencyTextFieldHelper.value(from: valueString) else { return false }
        return value < 0
    }

    private var hasInvalidValues: Bool {
        viewModel.items.contains { isInvalid(categoryId: $0.id) }
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
        viewModel.items.compactMap { item in
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
}

// MARK: - CurrencyMaskedTextField

struct CurrencyMaskedTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CurrencyMaskedTextField

        init(_ parent: CurrencyMaskedTextField) {
            self.parent = parent
        }

        @objc func textFieldEditingChanged(_ textField: UITextField) {
            // Remove any character except digits
            let digits = textField.text?.compactMap { $0.isWholeNumber ? $0 : nil } ?? []
            let digitString = String(digits)

            // Convert digits to number and format as currency
            let number = NSDecimalNumber(string: digitString).dividing(by: 100)

            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale(identifier: "pt_BR")
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2

            if let formatted = formatter.string(from: number) {
                textField.text = formatted
                parent.text = formatted
            } else {
                textField.text = ""
                parent.text = ""
            }
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Allow only digits and decimal separator
            let locale = Locale(identifier: "pt_BR")
            guard let decimalSeparator = locale.decimalSeparator else {
                return false
            }

            let allowedCharacters = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: decimalSeparator))

            if string.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
                return false
            }

            return true
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.keyboardType = .decimalPad
        textField.placeholder = placeholder
        textField.delegate = context.coordinator
        textField.text = text
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldEditingChanged(_:)), for: .editingChanged)
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.borderStyle = .none
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.tintColor = UIColor.label
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }
}

// MARK: - CurrencyTextFieldHelper Helpers

struct CurrencyTextFieldHelper {
    static func value(from text: String) -> Double? {
        // Remove currency symbols, spaces and dots, replace comma with dot for decimal separator
        let cleaned = text
            .replacingOccurrences(of: "R$", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { return nil }
        return Double(cleaned)
    }

    static func initialText(from value: Double) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value))
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

