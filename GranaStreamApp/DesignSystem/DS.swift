import SwiftUI
import UIKit

enum DS {
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

    enum Brand {
        static let brandCyan = Color.token("BrandCyan", fallback: "00D1FF")
        static let brandBlue = Color.token("BrandBlue", fallback: "0068FF")
        static let brandPurple = Color.token("BrandPurple", fallback: "7B2FF7")
        static let brandMagenta = Color.token("BrandMagenta", fallback: "FF2DB2")
    }

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
