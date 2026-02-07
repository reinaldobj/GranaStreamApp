import SwiftUI

struct TransactionFiltersView: View {
    @Binding var filters: TransactionFilters
    var onApply: () -> Void

    @EnvironmentObject private var referenceStore: ReferenceDataStore
    @Environment(\.dismiss) private var dismiss

    @State private var dateMode: DateMode = .monthYear
    @State private var selectedStartDate = Date()
    @State private var selectedEndDate = Date()
    @State private var selectedMonth = Calendar.current.component(.month, from: Date())
    @State private var selectedYear = Calendar.current.component(.year, from: Date())
    @State private var selectedType: TransactionType?

    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.background
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.item) {
                        header
                        searchField
                        filterCard
                    }
                    .padding(.horizontal, AppTheme.Spacing.screen)
                    .padding(.top, AppTheme.Spacing.screen)
                    .padding(.bottom, AppTheme.Spacing.screen * 2)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                let calendar = Calendar.current
                let start = min(filters.startDate, filters.endDate)
                let end = max(filters.startDate, filters.endDate)

                selectedStartDate = start
                selectedEndDate = end
                selectedMonth = calendar.component(.month, from: start)
                selectedYear = calendar.component(.year, from: start)

                let startComponents = calendar.dateComponents([.year, .month, .day], from: start)
                let endComponents = calendar.dateComponents([.year, .month, .day], from: end)
                if startComponents.day == 1,
                   startComponents.month == endComponents.month,
                   startComponents.year == endComponents.year {
                    let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: start)) ?? start
                    let monthEnd = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) ?? end
                    dateMode = calendar.isDate(monthEnd, inSameDayAs: end) ? .monthYear : .calendar
                } else {
                    dateMode = .calendar
                }

                if let type = filters.type, type != .transfer {
                    selectedType = type
                } else {
                    selectedType = nil
                }
            }
        }
        .tint(DS.Colors.primary)
    }

    private var header: some View {
        HStack {
            Spacer()
            Text("Filtros")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(DS.Colors.textPrimary)
            Spacer()
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(DS.Colors.textSecondary)

            TextField("Buscar...", text: $filters.searchText)
                .textInputAutocapitalization(.sentences)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DS.Colors.surface2)
        .clipShape(Capsule())
    }

    private var filterCard: some View {
        VStack(spacing: AppTheme.Spacing.item) {
            dateModeTabs

            if dateMode == .monthYear {
                monthYearPickers
            } else {
                TransactionDateRow(label: "De", date: $selectedStartDate)
                TransactionDateRow(label: "Ate", date: $selectedEndDate)
            }

            TransactionPickerRow(
                label: "Categorias",
                value: categoryName,
                placeholder: "Selecione a categoria"
            ) {
                Button("Todas") {
                    filters.categoryId = nil
                }
                ForEach(referenceStore.categories) { category in
                    Button(category.name ?? "Categoria") {
                        filters.categoryId = category.id
                    }
                }
            }

            filterTypeSelector

            TransactionPrimaryButton(title: "Buscar") {
                applyFilters()
                onApply()
                dismiss()
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(DS.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: DS.Colors.border.opacity(0.25), radius: 10, x: 0, y: 6)
    }

    private var dateModeTabs: some View {
        HStack(spacing: 12) {
            FilterTabButton(
                title: "Mes/Ano",
                isSelected: dateMode == .monthYear
            ) {
                dateMode = .monthYear
            }

            FilterTabButton(
                title: "Calendario",
                isSelected: dateMode == .calendar
            ) {
                dateMode = .calendar
            }
        }
    }

    private var monthYearPickers: some View {
        HStack(spacing: AppTheme.Spacing.item) {
            Menu {
                ForEach(1...12, id: \.self) { month in
                    Button(monthName(for: month)) {
                        selectedMonth = month
                    }
                }
            } label: {
                TransactionField(label: "Mes") {
                    Text(monthName(for: selectedMonth))
                        .foregroundColor(DS.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DS.Colors.textSecondary)
                }
            }
            .buttonStyle(.plain)

            Menu {
                ForEach(yearOptions, id: \.self) { year in
                    Button(String(year)) {
                        selectedYear = year
                    }
                }
            } label: {
                TransactionField(label: "Ano") {
                    Text(String(selectedYear))
                        .foregroundColor(DS.Colors.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(DS.Colors.textSecondary)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var filterTypeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tipo")
                .font(AppTheme.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)

            HStack(spacing: 12) {
                FilterPillButton(
                    title: "Receita",
                    isSelected: selectedType == .income
                ) {
                    toggleType(.income)
                }

                FilterPillButton(
                    title: "Despesa",
                    isSelected: selectedType == .expense
                ) {
                    toggleType(.expense)
                }
            }
        }
    }

    private var categoryName: String? {
        referenceStore.categories.first(where: { $0.id == filters.categoryId })?.name
    }

    private func applyFilters() {
        let calendar = Calendar.current
        if dateMode == .monthYear {
            var components = DateComponents()
            components.year = selectedYear
            components.month = selectedMonth
            components.day = 1
            let startOfMonth = calendar.date(from: components) ?? Date()
            let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) ?? startOfMonth
            filters.startDate = startOfMonth
            filters.endDate = endOfMonth
        } else {
            let start = min(selectedStartDate, selectedEndDate)
            let end = max(selectedStartDate, selectedEndDate)
            let startOfDay = calendar.startOfDay(for: start)
            let endOfDay = calendar.date(byAdding: DateComponents(day: 1, second: -1), to: calendar.startOfDay(for: end)) ?? end
            filters.startDate = startOfDay
            filters.endDate = endOfDay
        }
        filters.type = selectedType
        filters.accountId = nil
    }

    private func toggleType(_ type: TransactionType) {
        if selectedType == type {
            selectedType = nil
        } else {
            selectedType = type
        }
    }
}

private enum DateMode {
    case monthYear
    case calendar
}

private struct FilterTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.body)
                .foregroundColor(isSelected ? DS.Colors.onPrimary : DS.Colors.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(
                    Capsule()
                        .fill(isSelected ? DS.Colors.primary : DS.Colors.surface2)
                )
        }
        .buttonStyle(.plain)
    }
}

private struct FilterPillButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(AppTheme.Typography.body)
                .foregroundColor(isSelected ? DS.Colors.onPrimary : DS.Colors.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 40)
                .background(
                    Capsule()
                        .fill(isSelected ? DS.Colors.primary : DS.Colors.surface2)
                )
        }
        .buttonStyle(.plain)
    }
}

private extension TransactionFiltersView {
    var yearOptions: [Int] {
        let current = Calendar.current.component(.year, from: Date())
        return Array((current - 5)...(current + 5))
    }

    func monthName(for month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        return formatter.monthSymbols[month - 1].capitalized
    }
}
