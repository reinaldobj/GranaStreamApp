import SwiftUI

struct LaunchScreenView: View {
    var body: some View {
        ZStack {
            Color("Background")
                .ignoresSafeArea()

            Image("SplashScreen")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    LaunchScreenView()
}
