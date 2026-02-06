import SwiftUI

struct SkeletonCard: View {
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.base) {
                SkeletonLine(height: 16, widthFraction: 0.6)
                SkeletonLine(height: 12, widthFraction: 0.35)
            }
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
        }
    }
}
