import SwiftUI

struct SkeletonLine: View {
    var height: CGFloat = 12
    var widthFraction: CGFloat? = nil

    var body: some View {
        GeometryReader { geometry in
            RoundedRectangle(cornerRadius: height / 2)
                .fill(DS.Colors.surface2.opacity(DS.Opacity.strong))
                .frame(
                    width: lineWidth(in: geometry.size.width),
                    height: height,
                    alignment: .leading
                )
        }
        .frame(height: height)
    }

    private func lineWidth(in totalWidth: CGFloat) -> CGFloat {
        guard let widthFraction else { return totalWidth }
        return max(0, min(1, widthFraction)) * totalWidth
    }
}
