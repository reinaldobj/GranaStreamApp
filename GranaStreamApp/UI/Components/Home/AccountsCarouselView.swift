import SwiftUI

struct AccountsCarouselView: View {
    let accounts: [HomeAccountCardItem]

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: DS.Spacing.item) {
                AppSectionHeader(text: L10n.Home.accountsTitle)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Spacing.item) {
                        ForEach(accounts) { account in
                            NavigationLink {
                                AccountDetailView(account: account)
                            } label: {
                                AccountCardView(account: account)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
