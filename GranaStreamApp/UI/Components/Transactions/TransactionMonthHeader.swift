import SwiftUI

struct TransactionMonthHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(AppTheme.Typography.section)
            .foregroundColor(DS.Colors.textPrimary)
    }
}
