import SwiftUI

struct AppCard<Content: View>: View {
    private let content: Content
    @Environment(\.colorScheme) private var colorScheme

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(DS.Spacing.cardPadding)
            .background(DS.Colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.card)
                    .stroke(DS.Colors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.card))
            .shadow(
                color: DS.Shadow.cardColor.opacity(shadowOpacity),
                radius: DS.Shadow.cardRadius,
                x: DS.Shadow.cardX,
                y: DS.Shadow.cardY
            )
    }

    private var shadowOpacity: Double {
        colorScheme == .dark ? DS.Shadow.cardOpacityDark : DS.Shadow.cardOpacityLight
    }
}
