import SwiftUI

struct HomeTopHeaderView: View {
    @EnvironmentObject private var session: SessionStore

    var body: some View {
        HStack(alignment: .center, spacing: DS.Spacing.item) {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(L10n.Home.welcome), \(displayName)")
                    .font(DS.Typography.title)
                    .foregroundColor(DS.Colors.onPrimary)
                Text(L10n.Home.overview)
                    .font(DS.Typography.caption)
                    .foregroundColor(DS.Colors.onPrimary.opacity(0.85))
            }

            Spacer()

            Image(systemName: "bell")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(DS.Colors.onPrimary)
                .frame(width: 34, height: 34)
                .background(DS.Colors.onPrimary.opacity(0.15))
                .clipShape(Circle())
        }
    }

    private var displayName: String {
        let raw = session.profile?.name ?? session.currentUser?.name ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "Perfil" }
        return String(trimmed.split(separator: " ").first ?? "Perfil")
    }
}

#Preview {
    HomeTopHeaderView()
        .padding()
        .background(DS.Colors.primary)
        .environmentObject(SessionStore.shared)
}
