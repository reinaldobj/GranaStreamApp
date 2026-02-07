import SwiftUI

struct AppSectionHeader: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppTheme.Typography.section)
            .foregroundColor(DS.Colors.textPrimary)
    }
}
