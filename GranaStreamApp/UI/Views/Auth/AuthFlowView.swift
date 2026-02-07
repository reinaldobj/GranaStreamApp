    import SwiftUI

struct AuthFlowView: View {
    @ObservedObject var session: SessionStore
    @State private var stack: [AuthScreen] = [.landing]
    @State private var dragOffset: CGFloat = 0
    @State private var isDraggingBack = false

    var body: some View {
        GeometryReader { proxy in
            let screenWidth = proxy.size.width

            ZStack {
                if let previous = previousScreen {
                    screenView(previous)
                        .opacity(dragOffset > 0 ? 1 : 0)
                        .offset(x: -min(40, dragOffset / 6))
                        .allowsHitTesting(false)
                        .scrollDisabled(isDraggingBack)
                }

                screenView(currentScreen)
                    .offset(x: dragOffset)
                    .shadow(
                        color: Color.black.opacity(dragOffset > 0 ? 0.08 : 0),
                        radius: 12,
                        x: -4,
                        y: 0
                    )
                    .scrollDisabled(isDraggingBack)
            }
            .contentShape(Rectangle())
            .simultaneousGesture(backGesture(screenWidth: screenWidth))
            .onChange(of: stack.count) { _ in
                dragOffset = 0
                isDraggingBack = false
            }
        }
    }

    private var currentScreen: AuthScreen {
        stack.last ?? .landing
    }

    private var previousScreen: AuthScreen? {
        guard stack.count > 1 else { return nil }
        return stack[stack.count - 2]
    }

    @ViewBuilder
    private func screenView(_ screen: AuthScreen) -> some View {
        switch screen {
        case .landing:
            AuthLandingView(
                onLogin: { push(.login) },
                onSignup: { push(.signup) }
            )
        case .login:
            LoginView(
                session: session,
                onSignup: { push(.signup) }
            )
        case .signup:
            SignupView(
                onLogin: { returnToLogin() }
            )
        }
    }

    private func push(_ screen: AuthScreen) {
        guard stack.last != screen else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            stack.append(screen)
        }
    }

    private func pop(animated: Bool = true) {
        guard stack.count > 1 else { return }
        if animated {
            withAnimation(.easeInOut(duration: 0.2)) {
                stack.removeLast()
            }
        } else {
            stack.removeLast()
        }
    }

    private func returnToLogin() {
        if previousScreen == .login {
            pop()
        } else {
            withAnimation(.easeInOut(duration: 0.2)) {
                if stack.isEmpty {
                    stack = [.landing, .login]
                } else {
                    stack[stack.count - 1] = .login
                }
            }
        }
    }

    private func backGesture(screenWidth: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onChanged { value in
                guard stack.count > 1 else { return }
                let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                guard value.translation.width > 0, isHorizontal else { return }
                isDraggingBack = true
                dragOffset = min(value.translation.width, screenWidth)
            }
            .onEnded { value in
                guard stack.count > 1 else { return }
                defer { isDraggingBack = false }

                let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                guard value.translation.width > 0, isHorizontal else {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                        dragOffset = 0
                    }
                    return
                }

                let shouldPop = value.translation.width > 120
                if shouldPop {
                    withAnimation(.easeOut(duration: 0.2)) {
                        dragOffset = screenWidth
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        pop(animated: false)
                        dragOffset = 0
                    }
                } else {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.9)) {
                        dragOffset = 0
                    }
                }
            }
    }
}

private enum AuthScreen {
    case landing
    case login
    case signup
}
