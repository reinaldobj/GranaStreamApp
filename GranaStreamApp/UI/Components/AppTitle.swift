import SwiftUI

struct AppTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppTheme.Typography.title)
            .foregroundColor(DS.Colors.textPrimary)
    }
}

struct AppSectionHeader: View {
    let text: String

    var body: some View {
        Text(text)
            .font(AppTheme.Typography.section)
            .foregroundColor(DS.Colors.textPrimary)
    }
}
