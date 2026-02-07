import SwiftUI

struct PlanningView: View {
    var body: some View {
        CategoryBudgetsView(isPlanningRoot: true)
    }
}

struct PlanningView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PlanningView()
                .preferredColorScheme(.light)

            PlanningView()
                .preferredColorScheme(.dark)
        }
        .environmentObject(SessionStore.shared)
        .environmentObject(MonthFilterStore())
        .environmentObject(ReferenceDataStore.shared)
    }
}
