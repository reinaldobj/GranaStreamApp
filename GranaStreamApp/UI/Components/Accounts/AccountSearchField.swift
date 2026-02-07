import SwiftUI

struct AccountSearchField: View {
    @Binding var text: String
    var onSubmit: () -> Void

    var body: some View {
        AppSearchField(
            placeholder: "Buscar conta por nome",
            text: $text,
            onSubmit: onSubmit
        )
    }
}
