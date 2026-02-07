import SwiftUI

enum AppTheme {
    enum Typography {
        static let title = Font.system(size: 22, weight: .semibold)
        static let section = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 15, weight: .regular)
        static let caption = Font.system(size: 13, weight: .regular)
        static let metric = Font.system(size: 24, weight: .semibold)
    }

    enum Spacing {
        static let base: CGFloat = 8
        static let item: CGFloat = 12
        static let screen: CGFloat = 16
        static let controlHeight: CGFloat = 48
        static let cardPadding: CGFloat = 16
    }

    enum Radius {
        static let card: CGFloat = 16
        static let button: CGFloat = 14
        static let field: CGFloat = 12
    }

    enum Shadow {
        static let cardColor = DS.Colors.border
        static let cardOpacityLight: Double = 0.35
        static let cardOpacityDark: Double = 0.2
        static let cardRadius: CGFloat = 8
        static let cardX: CGFloat = 0
        static let cardY: CGFloat = 2
    }
}
