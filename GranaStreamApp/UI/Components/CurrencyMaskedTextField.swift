import SwiftUI
import UIKit

/// Campo de texto com máscara de moeda brasileira (R$)
/// Aceita apenas dígitos e formata automaticamente como valor monetário
struct CurrencyMaskedTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CurrencyMaskedTextField

        init(_ parent: CurrencyMaskedTextField) {
            self.parent = parent
        }

        @objc func textFieldEditingChanged(_ textField: UITextField) {
            // Remove any character except digits
            let digits = textField.text?.compactMap { $0.isWholeNumber ? $0 : nil } ?? []
            let digitString = String(digits)

            // Convert digits to number and format as currency
            let number = NSDecimalNumber(string: digitString).dividing(by: 100)

            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale(identifier: "pt_BR")
            formatter.maximumFractionDigits = 2
            formatter.minimumFractionDigits = 2

            if let formatted = formatter.string(from: number) {
                textField.text = formatted
                parent.text = formatted
            } else {
                textField.text = ""
                parent.text = ""
            }
        }

        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            // Allow only digits and decimal separator
            let locale = Locale(identifier: "pt_BR")
            guard let decimalSeparator = locale.decimalSeparator else {
                return false
            }

            let allowedCharacters = CharacterSet.decimalDigits.union(CharacterSet(charactersIn: decimalSeparator))

            if string.rangeOfCharacter(from: allowedCharacters.inverted) != nil {
                return false
            }

            return true
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.keyboardType = .decimalPad
        textField.placeholder = placeholder
        textField.delegate = context.coordinator
        textField.text = text
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldEditingChanged(_:)), for: .editingChanged)
        textField.font = UIFont.preferredFont(forTextStyle: .body)
        textField.borderStyle = .none
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.tintColor = UIColor.label
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }
}

// MARK: - Helpers

struct CurrencyTextFieldHelper {
    /// Converte texto formatado como moeda para valor Double
    /// Ex: "R$ 1.234,56" -> 1234.56
    static func value(from text: String) -> Double? {
        let cleaned = text
            .replacingOccurrences(of: "R$", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else { return nil }
        return Double(cleaned)
    }

    /// Converte valor Double para texto formatado como moeda
    /// Ex: 1234.56 -> "R$ 1.234,56"
    static func initialText(from value: Double) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value))
    }
}

// MARK: - Preview

#Preview {
    VStack {
        CurrencyMaskedTextField(
            text: .constant("R$ 1.234,56"),
            placeholder: "R$ 0,00"
        )
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding()
    }
}
