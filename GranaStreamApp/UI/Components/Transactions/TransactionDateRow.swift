import SwiftUI

struct TransactionDateRow: View {
    let label: String
    @Binding var date: Date
    @State private var showPicker = false

    var body: some View {
        Button {
            showPicker = true
        } label: {
            TransactionField(label: label) {
                Text(date.formattedDate())
                    .foregroundColor(DS.Colors.textPrimary)

                Spacer()

                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(DS.Colors.primary)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPicker) {
            NavigationStack {
                VStack(spacing: 16) {
                    DatePicker("Data", selection: $date, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()

                    Button("Ok") {
                        showPicker = false
                    }
                    .font(AppTheme.Typography.section)
                    .frame(maxWidth: .infinity, minHeight: AppTheme.Spacing.controlHeight)
                    .foregroundColor(DS.Colors.onPrimary)
                    .background(
                        Capsule()
                            .fill(DS.Colors.primary)
                    )
                }
                .padding(AppTheme.Spacing.screen)
                .navigationTitle("Selecionar data")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Fechar") {
                            showPicker = false
                        }
                    }
                }
            }
            .tint(DS.Colors.primary)
        }
    }
}

struct TransactionDateInlineRow: View {
    let label: String
    @Binding var date: Date

    var body: some View {
        TransactionField(label: label) {
            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(.compact)
                .labelsHidden()
                .foregroundColor(DS.Colors.textPrimary)

            Spacer()

            Image(systemName: "calendar")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(DS.Colors.primary)
        }
    }
}
