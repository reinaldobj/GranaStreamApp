import SwiftUI

struct AppHeaderView: View {
    @EnvironmentObject private var session: SessionStore
    @EnvironmentObject private var monthStore: MonthFilterStore
    @State private var showProfileSheet = false

    var body: some View {
        AppCard {
            HStack(alignment: .center, spacing: AppTheme.Spacing.item) {
                Button {
                    showProfileSheet = true
                } label: {
                    HStack(spacing: AppTheme.Spacing.item) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 36))
                            .foregroundColor(DS.Colors.primary)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(greetingText)
                                .font(AppTheme.Typography.caption)
                                .foregroundColor(DS.Colors.textSecondary)

                            Text(displayName)
                                .font(AppTheme.Typography.title)
                                .foregroundColor(DS.Colors.textPrimary)
                        }
                    }
                }
                .buttonStyle(.plain)

                Spacer(minLength: AppTheme.Spacing.base)

                Menu {
                    ForEach(monthStore.monthsInYear, id: \.self) { month in
                        Button(monthStore.label(for: month)) {
                            monthStore.select(month: month)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Text(monthStore.selectedMonthLabel)
                        Image(systemName: "chevron.down")
                    }
                    .font(AppTheme.Typography.caption)
                    .foregroundColor(DS.Colors.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DS.Colors.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(DS.Colors.border, lineWidth: 1)
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .sheet(isPresented: $showProfileSheet) {
            ProfileView()
                .environmentObject(session)
                .presentationDetents([.fraction(0.80)])
                .presentationDragIndicator(.visible)
        }
    }

    private var displayName: String {
        let trimmed = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(whereSeparator: { $0 == " " })
        if let first = parts.first, !first.isEmpty {
            return String(first)
        }
        return "Perfil"
    }

    private var greetingText: String {
        let trimmed = profileName.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return "Olá,"
        }
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Bom dia," }
        if hour < 18 { return "Boa tarde," }
        return "Boa noite,"
    }

    private var profileName: String {
        session.profile?.name ?? session.currentUser?.name ?? ""
    }
}

struct AppHeaderView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationStack {
                AppHeaderView()
                    .padding()
            }
            .preferredColorScheme(.light)

            NavigationStack {
                AppHeaderView()
                    .padding()
            }
            .preferredColorScheme(.dark)
        }
        .environmentObject(SessionStore.shared)
        .environmentObject(MonthFilterStore())
    }
}
