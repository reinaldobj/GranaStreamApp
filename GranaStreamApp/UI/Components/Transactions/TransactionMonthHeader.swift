import SwiftUI

struct TransactionMonthHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(DS.Typography.section)
            .foregroundColor(DS.Colors.textPrimary)
    }
}
