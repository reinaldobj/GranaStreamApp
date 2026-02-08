import SwiftUI

struct CategoryRowView: View {
    let category: CategoryResponseDto

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.md) {
            ZStack {
                Circle()
                    .fill(DS.Colors.primary.opacity(DS.Opacity.backgroundOverlay))
                    .frame(width: DS.Spacing.iconLarge, height: DS.Spacing.iconLarge)

                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(DS.Colors.primary)
            }

            VStack(alignment: .leading, spacing: DS.Spacing.xs) {
                Text(category.name ?? "Categoria")
                    .font(AppTheme.Typography.section)
                    .foregroundColor(DS.Colors.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(secondaryText)
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(DS.Colors.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: DS.Spacing.sm)
        }
        .padding(.trailing, DS.Spacing.sm)
    }

    private var iconName: String {
        switch category.categoryType {
        case .income:
            return "arrow.down.left"
        case .expense:
            return "arrow.up.right"
        case .both:
            return "arrow.left.arrow.right"
        case .none:
            return "tag.fill"
        }
    }

    private var secondaryText: String {
        let type = category.categoryTypeLabel
        if let parentName = category.parentCategoryName?.trimmingCharacters(in: .whitespacesAndNewlines),
           !parentName.isEmpty {
            return "\(type) • \(parentName)"
        }
        return type
    }
}
