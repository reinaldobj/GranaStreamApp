import SwiftUI
import UIKit

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences
    var autocorrectionDisabled: Bool = false

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            if text.isEmpty {
                Text(placeholder)
                    .font(AppTheme.Typography.body)
                    .foregroundColor(DS.Colors.textSecondary)
                    .padding(.horizontal, AppTheme.Spacing.item)
            }

            field
                .font(AppTheme.Typography.body)
                .foregroundColor(DS.Colors.textPrimary)
                .padding(.horizontal, AppTheme.Spacing.item)
        }
        .frame(minHeight: AppTheme.Spacing.controlHeight)
        .background(DS.Colors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Radius.field)
                .stroke(isFocused ? DS.Colors.primary : DS.Colors.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Radius.field))
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
                .padding(.vertical, AppTheme.Spacing.item)
        } else {
            TextField("", text: $text)
                .focused($isFocused)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(autocorrectionDisabled)
                .padding(.vertical, AppTheme.Spacing.item)
        }
    }
}
