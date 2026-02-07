import SwiftUI

struct CategorySearchField: View {
    @Binding var text: String
    var onSubmit: () -> Void

    var body: some View {
        AppSearchField(
            placeholder: "Buscar categoria por nome",
            text: $text,
            onSubmit: onSubmit
        )
    }
}
