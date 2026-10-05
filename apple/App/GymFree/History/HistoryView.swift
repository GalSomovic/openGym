import OpenGymCore
import SwiftUI

/// openGym's History view: every workout, newest first, and logging one from the past.
struct HistoryView: View {
    @Environment(GymStore.self) private var store
    @Environment(TodayRouter.self) private var router
    @Environment(WorkoutSession.self) private var session

    var body: some View {
        let rows = store.historyRows()
        List {
            Section {
                Button {
                    if store.active != nil { session.toast = String(localized: "Finish the current workout first.") }
                    else { router.sheet = .logPast(nil) }
                } label: {
                    Label("Log a past workout", systemImage: "plus")
                }
            }
            if rows.isEmpty {
                ContentUnavailableView("No workouts yet.", systemImage: "clock.arrow.circlepath")
                    .listRowBackground(Color.clear)
            } else {
                Section(store.historyCount()) {
                    ForEach(rows) { row in
                        NavigationLink(value: TodayRouter.Route.workout(row.key)) { WorkoutRowView(row: row) }
                    }
                }
            }
        }
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { router.sheet = .calendar } label: { Image(systemName: "calendar") }
                    .accessibilityLabel(Text("Calendar"))
            }
        }
    }
}
