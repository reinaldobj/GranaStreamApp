import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house") }

            TransactionsView()
                .tabItem { Label("Lançamentos", systemImage: "list.bullet.rectangle") }

            PlanningView()
                .tabItem { Label("Planejamento", systemImage: "calendar") }

            SettingsView()
                .tabItem { Label("Config", systemImage: "gearshape") }
        }
        .tint(DS.Colors.primary)
    }
}
