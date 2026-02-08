import SwiftUI

struct AppSectionHeader: View {
    let text: String

    var body: some View {
        Text(text)
            .font(DS.Typography.section)
            .foregroundColor(DS.Colors.textPrimary)
    }
}
