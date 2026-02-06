import SwiftUI

extension View {
    func errorAlert(message: Binding<String?>) -> some View {
        alert("Erro", isPresented: Binding(
            get: { message.wrappedValue != nil },
            set: { if !$0 { message.wrappedValue = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(message.wrappedValue ?? "Erro")
        }
    }
}
