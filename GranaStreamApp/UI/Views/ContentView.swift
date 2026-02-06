import SwiftUI

struct ContentView: View {
    var body: some View {
        RootView()
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
