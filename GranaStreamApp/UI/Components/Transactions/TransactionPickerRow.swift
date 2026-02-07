import SwiftUI

struct TransactionPickerRow<MenuContent: View>: View {
    let label: String
    let value: String?
    let placeholder: String
    private let menuContent: MenuContent

    init(
        label: String,
        value: String?,
        placeholder: String,
        @ViewBuilder menuContent: () -> MenuContent
    ) {
        self.label = label
        self.value = value
        self.placeholder = placeholder
        self.menuContent = menuContent()
    }

    var body: some View {
        Menu {
            menuContent
        } label: {
            TransactionField(label: label) {
                Text(value ?? placeholder)
                    .foregroundColor(value == nil ? DS.Colors.textSecondary : DS.Colors.textPrimary)

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(DS.Colors.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}
