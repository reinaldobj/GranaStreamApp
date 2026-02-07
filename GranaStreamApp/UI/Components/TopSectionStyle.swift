import SwiftUI
import UIKit

struct TopRoundedShape: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func topSectionStyle(radius: CGFloat = 44) -> some View {
        background(DS.Colors.surface2)
            .clipShape(TopRoundedShape(radius: radius))
            .shadow(color: DS.Colors.border.opacity(0.15), radius: 8, x: 0, y: -2)
    }
}
