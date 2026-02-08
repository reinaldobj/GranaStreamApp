import SwiftUI

struct SettingsMenuRow: View {
    let title: String
    let systemImage: String
    var isDestructive: Bool = false
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: DS.Spacing.item) {
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: DS.Spacing.iconLarge, height: DS.Spacing.iconLarge)

                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            Text(title)
                .font(DS.Typography.section)
                .foregroundColor(titleColor)

            Spacer()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DS.Colors.textSecondary)
            }
        }
        .padding(.horizontal, DS.Spacing.md)
        .padding(.vertical, DS.Spacing.md)
        .background(DS.Colors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var iconBackground: Color {
        isDestructive ? DS.Colors.error.opacity(DS.Opacity.backgroundOverlay) : DS.Colors.primary.opacity(DS.Opacity.backgroundOverlay)
    }

    private var iconColor: Color {
        isDestructive ? DS.Colors.error : DS.Colors.primary
    }

    private var titleColor: Color {
        isDestructive ? DS.Colors.error : DS.Colors.textPrimary
    }
}

struct SettingsMenuRow_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 12) {
            SettingsMenuRow(title: "Contas", systemImage: "wallet.pass")
            SettingsMenuRow(title: "Categorias", systemImage: "square.grid.2x2")
            SettingsMenuRow(title: "Sair", systemImage: "rectangle.portrait.and.arrow.right", isDestructive: true, showsChevron: false)
        }
        .padding()
        .background(DS.Colors.surface2)
    }
}
