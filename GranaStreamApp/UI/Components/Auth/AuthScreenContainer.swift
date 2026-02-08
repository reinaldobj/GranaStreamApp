import SwiftUI

struct AuthScreenContainer<Content: View>: View {
    let title: String
    let subtitle: String?
    private let content: Content

    init(
        title: String,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let safeTop = proxy.safeAreaInsets.top
            let topHeight = max(190, proxy.size.height * 0.28)
            let contentTopPadding = safeTop + 12

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    DS.Colors.primary
                        .frame(height: topHeight)
                        .frame(maxWidth: .infinity)

                    DS.Colors.background
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppTheme.Spacing.item) {
                        header

                        AuthCard {
                            content
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.screen)
                    .padding(.top, contentTopPadding)
                    .padding(.bottom, AppTheme.Spacing.screen * 2)
                }
            }
            .ignoresSafeArea(edges: .top)
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(DS.Colors.onPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(DS.Colors.onPrimary.opacity(DS.Opacity.emphasisTextStrong))
            }
        }
        .multilineTextAlignment(.center)
    }
}

struct AuthCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(DS.Spacing.xl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: DS.Colors.border.opacity(DS.Opacity.hoverState), radius: 10, x: 0, y: 6)
    }
}
