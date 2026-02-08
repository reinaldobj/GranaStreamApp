import SwiftUI

struct LoadingPillView: View {
    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(DS.Colors.primary)
                .scaleEffect(0.9)
            Text("Carregando...")
                .font(DS.Typography.caption)
                .foregroundColor(DS.Colors.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(DS.Colors.surface2)
        .overlay(
            Capsule()
                .stroke(DS.Colors.border, lineWidth: 1)
        )
        .clipShape(Capsule())
    }
}
