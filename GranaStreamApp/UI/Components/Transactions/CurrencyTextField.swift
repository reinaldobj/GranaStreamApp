import SwiftUI

struct CurrencyTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: Binding(
            get: { text },
            set: { newValue in
                text = Self.formatInput(newValue)
            }
        ))
        .keyboardType(.numberPad)
        .foregroundColor(DS.Colors.textPrimary)
    }

    static func formatInput(_ input: String) -> String {
        let digits = input.compactMap { $0.wholeNumberValue }.map(String.init).joined()
        guard let number = Double(digits) else {
            return ""
        }
        let value = number / 100
        return CurrencyFormatter.string(from: value)
    }

    static func value(from input: String) -> Double? {
        let digits = input.compactMap { $0.wholeNumberValue }.map(String.init).joined()
        guard !digits.isEmpty, let number = Double(digits) else {
            return nil
        }
        return number / 100
    }
}
