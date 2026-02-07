import SwiftUI

struct TransactionPrimaryButton: View {
    let title: String
    var isDisabled: Bool = false
    let action: () -> Void

    var body: some View {
        AppPrimaryButton(
            title: title,
            isDisabled: isDisabled,
            action: action
        )
    }
}
