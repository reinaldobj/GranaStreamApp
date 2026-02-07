import SwiftUI

struct CurrencyTextField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        TextField(placeholder, text: Binding(
            get: { text },
            set: { newValue in
                text = Self.formatInput(newValue, previous: text)
            }
        ))
        .keyboardType(.numberPad)
        .foregroundColor(DS.Colors.textPrimary)
    }

    static func formatInput(_ input: String, previous: String = "") -> String {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ""
        }

        let previousDigits = integerDigits(from: previous)
        let digits: String

        if input.hasPrefix(previous), let last = input.last, last.isNumber {
            digits = previousDigits + String(last)
        } else if input.count < previous.count {
            var reduced = previousDigits
            if !reduced.isEmpty {
                reduced.removeLast()
            }
            digits = reduced
        } else {
            digits = integerDigits(from: input)
        }

        return formatFromIntegerDigits(digits)
    }

    static func value(from input: String) -> Double? {
        let normalized = input
            .replacingOccurrences(of: "R$", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: ".")

        guard !normalized.isEmpty, let value = Double(normalized) else {
            return nil
        }
        return value
    }

    private static func integerDigits(from input: String) -> String {
        let part = input.components(separatedBy: ",").first ?? ""
        let digits = part.compactMap { $0.wholeNumberValue }.map(String.init).joined()
        guard !digits.isEmpty else {
            return ""
        }

        let cleaned = digits.trimmingCharacters(in: CharacterSet(charactersIn: "0"))
        return cleaned.isEmpty ? "0" : cleaned
    }

    private static func formatFromIntegerDigits(_ digits: String) -> String {
        guard !digits.isEmpty else {
            return ""
        }

        let decimalValue = NSDecimalNumber(string: digits)
        guard decimalValue != .notANumber else {
            return ""
        }

        let integerFormatter = NumberFormatter()
        integerFormatter.locale = Locale(identifier: "pt_BR")
        integerFormatter.numberStyle = .decimal
        integerFormatter.maximumFractionDigits = 0

        let integerText = integerFormatter.string(from: decimalValue) ?? digits
        return "R$ \(integerText),00"
    }
}
