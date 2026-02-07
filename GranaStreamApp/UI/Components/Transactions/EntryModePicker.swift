import SwiftUI

enum UnifiedEntryMode: String, CaseIterable, Identifiable {
    case single
    case installment
    case recurring

    var id: String { rawValue }

    var label: String {
        switch self {
        case .single:
            return "Único"
        case .installment:
            return "Parcelado"
        case .recurring:
            return "Recorrente"
        }
    }
}

struct EntryModePicker: View {
    @Binding var selection: UnifiedEntryMode

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tipo de cadastro")
                .font(AppTheme.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)

            Picker("Tipo de cadastro", selection: $selection) {
                ForEach(UnifiedEntryMode.allCases) { item in
                    Text(item.label).tag(item)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
