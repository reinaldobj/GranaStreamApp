import SwiftUI

struct SettingsMenuRow: View {
    let title: String
    let systemImage: String
    var isDestructive: Bool = false
    var showsChevron: Bool = true

    var body: some View {
        HStack(spacing: AppTheme.Spacing.item) {
            ZStack {
                Circle()
                    .fill(iconBackground)
                    .frame(width: 42, height: 42)

                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            Text(title)
                .font(AppTheme.Typography.section)
                .foregroundColor(titleColor)

            Spacer()

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(DS.Colors.textSecondary)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(DS.Colors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(DS.Colors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var iconBackground: Color {
        isDestructive ? DS.Colors.error.opacity(0.18) : DS.Colors.primary.opacity(0.18)
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
