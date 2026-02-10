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
        .keyboardType(.decimalPad)
        .foregroundColor(DS.Colors.textPrimary)
    }

    static func formatInput(_ input: String) -> String {
        let cleaned = input
            .replacingOccurrences(of: "R$", with: "")
            .replacingOccurrences(of: " ", with: "")

        guard !cleaned.isEmpty else {
            return ""
        }

        var integerDigits = ""
        var fractionDigits = ""
        var hasSeparator = false
        var trailingSeparator = false

        for char in cleaned {
            if char.isNumber {
                if hasSeparator {
                    if fractionDigits.count < 2 {
                        fractionDigits.append(char)
                    }
                    trailingSeparator = false
                } else {
                    integerDigits.append(char)
                }
                continue
            }

            if (char == "," || char == ".") && !hasSeparator {
                hasSeparator = true
                trailingSeparator = true
            }
        }

        if integerDigits.isEmpty {
            if hasSeparator {
                integerDigits = "0"
            } else {
                return ""
            }
        }

        let formattedInteger = formatInteger(integerDigits)
        var result = "R$ \(formattedInteger)"

        if hasSeparator {
            if trailingSeparator {
                result += ","
            } else if !fractionDigits.isEmpty {
                result += ",\(fractionDigits)"
            }
        }

        return result
    }

    static func value(from input: String) -> Double? {
        let cleaned = input
            .replacingOccurrences(of: "R$", with: "")
            .replacingOccurrences(of: " ", with: "")

        guard !cleaned.isEmpty else {
            return nil
        }

        var normalized: String
        if cleaned.contains(",") {
            normalized = cleaned
                .replacingOccurrences(of: ".", with: "")
                .replacingOccurrences(of: ",", with: ".")
        } else {
            normalized = cleaned.replacingOccurrences(of: ".", with: "")
        }

        if normalized.hasSuffix(".") {
            normalized.removeLast()
        }

        guard !normalized.isEmpty, let value = Double(normalized) else {
            return nil
        }

        return value
    }

    static func initialText(from value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            let integerValue = Int(value)
            return "R$ \(formatInteger(String(integerValue)))"
        }

        let formatter = FormatterPool.brlDecimalTwoFormatter()
        let text = formatter.string(from: NSNumber(value: value)) ?? "0,00"
        return "R$ \(text)"
    }

    private static func formatInteger(_ digits: String) -> String {
        guard !digits.isEmpty else {
            return "0"
        }

        let onlyDigits = digits.compactMap { $0.wholeNumberValue }.map(String.init).joined()
        guard !onlyDigits.isEmpty else {
            return "0"
        }

        let normalized = onlyDigits.trimmingCharacters(in: CharacterSet(charactersIn: "0"))
        let value = normalized.isEmpty ? "0" : normalized
        let number = NSDecimalNumber(string: value)
        guard number != .notANumber else { return value }

        let formatter = FormatterPool.brlDecimalIntegerFormatter()

        return formatter.string(from: number) ?? value
    }
}
