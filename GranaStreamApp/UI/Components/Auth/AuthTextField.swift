import SwiftUI
import UIKit

struct AuthTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences
    var autocorrectionDisabled: Bool = false

    @FocusState private var isFocused: Bool

    var body: some View {
        AppFormField(label: label, isFocused: isFocused) {
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(AppTheme.Typography.body)
                        .foregroundColor(DS.Colors.textSecondary)
                }

                field
                    .font(AppTheme.Typography.body)
                    .foregroundColor(DS.Colors.textPrimary)
            }
        }
    }

    @ViewBuilder
    private var field: some View {
        if isSecure {
            SecureField("", text: $text)
                .focused($isFocused)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(autocorrectionDisabled)
        } else {
            TextField("", text: $text)
                .focused($isFocused)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(autocorrectionDisabled)
        }
    }
}
