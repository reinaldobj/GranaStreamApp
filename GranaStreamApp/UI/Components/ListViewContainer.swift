import SwiftUI

/// Componente reutilizável para layout de list views com background colorido no topo
/// Reduz duplicação do padrão ZStack + VStack + ScrollView
struct ListViewContainer<Content: View>: View {
    let primaryBackgroundHeight: CGFloat?
    let content: Content

    init(
        primaryBackgroundHeight: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.primaryBackgroundHeight = primaryBackgroundHeight
        self.content = content()
    }

    var body: some View {
        GeometryReader { proxy in
            let topBackgroundHeight = primaryBackgroundHeight ?? max(380, proxy.size.height * 0.56)

            ZStack(alignment: .top) {
                VStack(spacing: 0) {
                    DS.Colors.primary
                        .frame(height: topBackgroundHeight)
                        .frame(maxWidth: .infinity)

                    DS.Colors.surface2
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    content
                }
            }
        }
    }
}

#Preview {
    ListViewContainer {
        VStack(spacing: 16) {
            Text("Content here")
                .padding()
                .background(DS.Colors.surface)
                .cornerRadius(12)
                .padding()
        }
    }
}
