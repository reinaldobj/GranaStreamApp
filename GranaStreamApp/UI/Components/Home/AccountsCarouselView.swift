import SwiftUI

struct AccountsCarouselView: View {
    let accounts: [AccountSummary]

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: DS.Spacing.item) {
                AppSectionHeader(text: "Contas")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.item) {
                        ForEach(accounts) { account in
                            AccountCardView(account: account)
                        }
                    }
                }
            }
        }
    }
}
