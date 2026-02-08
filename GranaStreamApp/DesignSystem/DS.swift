import SwiftUI
import UIKit

/// Design System unificado - todos os tokens de design em um único namespace
enum DS {
    // MARK: - Colors
    
    enum Colors {
        static let background = Color.token("Background", fallback: "F7F7FF")
        static let surface = Color.token("Surface", fallback: "FFFFFF")
        static let surface2 = Color.token("Surface2", fallback: "F1F2FF")
        static let textPrimary = Color.token("TextPrimary", fallback: "0B0B12")
        static let textSecondary = Color.token("TextSecondary", fallback: "4B5563")
        static let border = Color.token("Border", fallback: "E5E7EB")
        static let primary = Color.token("Primary", fallback: "0068FF")
        static let onPrimary = Color.token("OnPrimary", fallback: "FFFFFF")
        static let accent = Color.token("Accent", fallback: "FF2DB2")
        static let success = Color.token("Success", fallback: "00DD9E")
        static let warning = Color.token("Warning", fallback: "F59E0B")
        static let error = Color.token("Error", fallback: "DC2626")
    }

    // MARK: - Brand Colors
    
    enum Brand {
        static let brandCyan = Color.token("BrandCyan", fallback: "00D1FF")
        static let brandBlue = Color.token("BrandBlue", fallback: "0068FF")
        static let brandPurple = Color.token("BrandPurple", fallback: "7B2FF7")
        static let brandMagenta = Color.token("BrandMagenta", fallback: "FF2DB2")
    }

    // MARK: - Gradients
    
    enum Gradients {
        static let brand = LinearGradient(
            colors: [
                Brand.brandCyan,
                Brand.brandBlue,
                Brand.brandPurple,
                Brand.brandMagenta
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Typography
    
    enum Typography {
        static let title = Font.system(size: 22, weight: .semibold)
        static let section = Font.system(size: 17, weight: .semibold)
        static let body = Font.system(size: 15, weight: .regular)
        static let caption = Font.system(size: 13, weight: .regular)
        static let metric = Font.system(size: 24, weight: .semibold)
    }

    // MARK: - Spacing
    
    enum Spacing {
        // Base units
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let base: CGFloat = 8
        static let md: CGFloat = 12
        static let item: CGFloat = 12
        static let lg: CGFloat = 16
        static let screen: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        
        // Specific usages
        static let cardPadding: CGFloat = 16
        static let formFieldSpacing: CGFloat = 12
        static let formTopPadding: CGFloat = 10
        static let buttonPadding: CGFloat = 16
        static let sectionSpacing: CGFloat = 24
        static let controlHeight: CGFloat = 48
        static let navigationBarHeight: CGFloat = 56
        
        // Icon sizes
        static let iconSmall: CGFloat = 20
        static let iconMedium: CGFloat = 24
        static let iconLarge: CGFloat = 32
        static let iconExtraLarge: CGFloat = 44
        
        // Avatar/Profile sizes
        static let avatarSmall: CGFloat = 32
        static let avatarMedium: CGFloat = 48
        static let avatarLarge: CGFloat = 64
    }
    
    // MARK: - Opacity
    
    enum Opacity {
        // Standard levels
        static let disabled: Double = 0.5
        static let subtle: Double = 0.25
        static let medium: Double = 0.45
        static let strong: Double = 0.75
        static let full: Double = 1.0
        
        // Specific UI usages
        static let backgroundOverlay: Double = 0.18
        static let buttonHover: Double = 0.32
        static let divider: Double = 0.25
        static let placeholderText: Double = 0.28
        static let selectedState: Double = 0.30
        static let hoverState: Double = 0.45
        static let disabledText: Double = 0.55
        static let secondaryText: Double = 0.70
        static let emphasisText: Double = 0.85
        static let emphasisTextStrong: Double = 0.88
    }

    // MARK: - Radius
    
    enum Radius {
        static let card: CGFloat = 16
        static let button: CGFloat = 14
        static let field: CGFloat = 12
    }

    // MARK: - Shadow
    
    enum Shadow {
        static let cardColor = Colors.border
        static let cardOpacityLight: Double = 0.35
        static let cardOpacityDark: Double = 0.2
        static let cardRadius: CGFloat = 8
        static let cardX: CGFloat = 0
        static let cardY: CGFloat = 2
    }
}

extension Color {
    static func token(_ name: String, fallback: String) -> Color {
        if let uiColor = UIColor(named: name) {
            return Color(uiColor)
        }
        return Color(hex: fallback)
    }

    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        guard Scanner(string: cleaned).scanHexInt64(&int) else {
            self = .clear
            return
        }
        switch cleaned.count {
        case 6:
            let red = Double((int >> 16) & 0xFF) / 255
            let green = Double((int >> 8) & 0xFF) / 255
            let blue = Double(int & 0xFF) / 255
            self.init(.sRGB, red: red, green: green, blue: blue, opacity: 1)
        case 8:
            let red = Double((int >> 24) & 0xFF) / 255
            let green = Double((int >> 16) & 0xFF) / 255
            let blue = Double((int >> 8) & 0xFF) / 255
            let alpha = Double(int & 0xFF) / 255
            self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
        default:
            self = .clear
        }
    }
}
