import SwiftUI

struct RootView: View {
    @StateObject private var session = SessionStore.shared
    @StateObject private var monthStore = MonthFilterStore()
    @StateObject private var referenceStore = ReferenceDataStore.shared

    var body: some View {
        Group {
            if session.isAuthenticated {
                MainTabView()
                    .environmentObject(session)
                    .environmentObject(monthStore)
                    .environmentObject(referenceStore)
            } else {
                AuthFlowView(session: session)
            }
        }
    }
}
