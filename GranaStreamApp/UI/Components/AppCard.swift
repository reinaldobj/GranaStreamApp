import SwiftUI

struct AppCard<Content: View>: View {
    private let content: Content
    @Environment(\.colorScheme) private var colorScheme

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppTheme.Spacing.cardPadding)
            .background(DS.Colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.Radius.card)
                    .stroke(DS.Colors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.card))
            .shadow(
                color: AppTheme.Shadow.cardColor.opacity(shadowOpacity),
                radius: AppTheme.Shadow.cardRadius,
                x: AppTheme.Shadow.cardX,
                y: AppTheme.Shadow.cardY
            )
    }

    private var shadowOpacity: Double {
        colorScheme == .dark ? AppTheme.Shadow.cardOpacityDark : AppTheme.Shadow.cardOpacityLight
    }
}
