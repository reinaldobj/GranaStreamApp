import SwiftUI

struct AccountField<Content: View>: View {
    let label: String
    private let content: Content

    init(label: String, @ViewBuilder content: () -> Content) {
        self.label = label
        self.content = content()
    }

    var body: some View {
        AppFormField(label: label) {
            content
        }
    }
}
