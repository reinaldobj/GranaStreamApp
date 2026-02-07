import SwiftUI

struct InitialsAvatarView: View {
    let name: String
    var size: CGFloat = 72

    var body: some View {
        ZStack {
            Circle()
                .fill(DS.Colors.primary.opacity(0.18))

            Text(initials)
                .font(.system(size: size * 0.34, weight: .semibold))
                .foregroundColor(DS.Colors.primary)
        }
        .frame(width: size, height: size)
    }

    private var initials: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "??" }

        let words = trimmed
            .split(separator: " ")
            .filter { !$0.isEmpty }

        if words.count >= 2 {
            let first = String(words.first?.prefix(1) ?? "?")
            let last = String(words.last?.prefix(1) ?? "?")
            return (first + last).uppercased()
        }

        if let firstWord = words.first {
            let chars = String(firstWord.prefix(2))
            return chars.uppercased()
        }

        return "??"
    }
}

struct InitialsAvatarView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            InitialsAvatarView(name: "Joao Silva")
            InitialsAvatarView(name: "Maria")
            InitialsAvatarView(name: "")
        }
        .padding()
    }
}
