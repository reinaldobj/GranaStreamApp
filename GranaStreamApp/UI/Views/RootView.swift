import SwiftUI

struct RootView: View {
    @StateObject private var session = SessionStore.shared
    @StateObject private var monthStore = MonthFilterStore()
    @StateObject private var referenceStore = ReferenceDataStore.shared
    @State private var showSignup = false

    var body: some View {
        Group {
            if session.isAuthenticated {
                MainTabView()
                    .environmentObject(session)
                    .environmentObject(monthStore)
                    .environmentObject(referenceStore)
            } else {
                NavigationStack {
                    LoginView(showSignup: $showSignup, session: session)
                        .navigationDestination(isPresented: $showSignup) {
                            SignupView(showSignup: $showSignup)
                        }
                }
            }
        }
    }
}

struct AuthFlowView: View {
    var body: some View {
        RootView()
    }
}
