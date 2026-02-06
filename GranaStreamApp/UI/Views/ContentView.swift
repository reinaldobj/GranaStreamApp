import SwiftUI

struct ContentView: View {
    @State private var showLaunchScreen = true

    var body: some View {
        ZStack {
            RootView()

            if showLaunchScreen {
                LaunchScreenView()
                    .transition(.opacity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showLaunchScreen = false
                }
            }
        }
    }
}

#Preview {
    Group {
        ContentView()
            .preferredColorScheme(.light)

        ContentView()
            .preferredColorScheme(.dark)
    }
}
