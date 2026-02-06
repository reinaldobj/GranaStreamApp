import SwiftUI

struct PlanningView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                DS.Colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppTheme.Spacing.item) {
                        AppHeaderView()
                        AppCard {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.base) {
                                Text("Recorrentes")
                                    .font(AppTheme.Typography.section)
                                    .foregroundColor(DS.Colors.textPrimary)
                                Text("Em breve")
                                    .font(AppTheme.Typography.body)
                                    .foregroundColor(DS.Colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        AppCard {
                            VStack(alignment: .leading, spacing: AppTheme.Spacing.base) {
                                Text("Parceladas")
                                    .font(AppTheme.Typography.section)
                                    .foregroundColor(DS.Colors.textPrimary)
                                Text("Em breve")
                                    .font(AppTheme.Typography.body)
                                    .foregroundColor(DS.Colors.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(AppTheme.Spacing.screen)
                }
            }
        }
        .tint(DS.Colors.primary)
    }
}

#Preview {
    Group {
        PlanningView()
            .preferredColorScheme(.light)

        PlanningView()
            .preferredColorScheme(.dark)
    }
    .environmentObject(SessionStore.shared)
    .environmentObject(MonthFilterStore())
}
