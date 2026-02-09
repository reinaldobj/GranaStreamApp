//
//  GranaStreamAppApp.swift
//  GranaStreamApp
//
//  Created by Reinaldo Junior on 04/02/26.
//

import SwiftUI

@main
struct GranaStreamAppApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { _, phase in
            AppLockService.shared.handleScenePhaseChange(phase)
            if phase == .active, SessionStore.shared.isAuthenticated {
                Task { await SessionStore.shared.ensureProfileLoadedIfNeeded() }
            }
        }
    }
}
