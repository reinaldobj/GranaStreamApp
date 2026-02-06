import SwiftUI

struct CatalogsView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink {
                    AccountsView()
                } label: {
                    AppCard {
                        Text("Contas")
                            .font(AppTheme.Typography.section)
                            .foregroundColor(DS.Colors.textPrimary)
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)

                NavigationLink {
                    CategoriesView()
                } label: {
                    AppCard {
                        Text("Categorias")
                            .font(AppTheme.Typography.section)
                            .foregroundColor(DS.Colors.textPrimary)
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)

                NavigationLink {
                    RecurrencesView()
                } label: {
                    AppCard {
                        Text("Recorrências")
                            .font(AppTheme.Typography.section)
                            .foregroundColor(DS.Colors.textPrimary)
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)

                NavigationLink {
                    InstallmentSeriesView()
                } label: {
                    AppCard {
                        Text("Parceladas")
                            .font(AppTheme.Typography.section)
                            .foregroundColor(DS.Colors.textPrimary)
                    }
                }
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowBackground(Color.clear)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(DS.Colors.background)
        }
        .tint(DS.Colors.primary)
    }
}
