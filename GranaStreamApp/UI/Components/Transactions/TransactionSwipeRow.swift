import SwiftUI

struct TransactionSwipeRow<Content: View>: View {
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    private let content: Content

    @State private var offsetX: CGFloat = 0
    @State private var isOpen = false

    private let actionWidth: CGFloat = 88
    private var totalActionWidth: CGFloat { actionWidth * 2 }

    init(
        onTap: @escaping () -> Void,
        onEdit: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.onTap = onTap
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.content = content()
    }

    var body: some View {
        ZStack(alignment: .trailing) {
            actionButtons

            content
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .background(DS.Colors.surface2)
                .offset(x: offsetX)
                .onTapGesture {
                    if isOpen {
                        closeActions()
                    } else {
                        onTap()
                    }
                }
                .simultaneousGesture(swipeGesture)
        }
        .clipped()
    }

    private var actionButtons: some View {
        HStack(spacing: 0) {
            Button {
                closeActions()
                onEdit()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "pencil")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Editar")
                        .font(DS.Typography.caption.weight(.semibold))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .foregroundColor(DS.Colors.onPrimary)
                .background(DS.Colors.primary)
            }

            Button(role: .destructive) {
                closeActions()
                onDelete()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "trash")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Excluir")
                        .font(DS.Typography.caption.weight(.semibold))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .tint(DS.Colors.error)
        }
        .frame(width: totalActionWidth)
        .frame(maxHeight: .infinity)
    }

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onChanged { value in
                let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                guard isHorizontal else { return }

                let base = isOpen ? -totalActionWidth : 0
                let proposed = base + value.translation.width
                offsetX = min(0, max(-totalActionWidth, proposed))
            }
            .onEnded { value in
                let isHorizontal = abs(value.translation.width) > abs(value.translation.height)
                guard isHorizontal else {
                    settlePosition(shouldOpen: isOpen)
                    return
                }

                let revealThreshold = totalActionWidth * 0.45
                let shouldOpen: Bool
                if isOpen {
                    shouldOpen = -offsetX > revealThreshold
                } else {
                    shouldOpen = value.translation.width < -32 || -offsetX > revealThreshold
                }
                settlePosition(shouldOpen: shouldOpen)
            }
    }

    private func settlePosition(shouldOpen: Bool) {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.9)) {
            isOpen = shouldOpen
            offsetX = shouldOpen ? -totalActionWidth : 0
        }
    }

    private func closeActions() {
        settlePosition(shouldOpen: false)
    }
}
