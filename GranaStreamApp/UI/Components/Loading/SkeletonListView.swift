import SwiftUI

struct SkeletonListView: View {
    var count: Int = 6

    var body: some View {
        List {
            ForEach(0..<count, id: \.self) { _ in
                SkeletonCard()
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(DS.Colors.background)
    }
}
