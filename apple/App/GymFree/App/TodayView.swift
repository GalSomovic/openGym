import OpenGymCore
import SwiftUI

/// openGym's start screen: today's plan, the other routines, freestyle. A running session
/// takes the whole tab.
struct TodayView: View {
    @Binding var tab: AppTab
    @Environment(GymStore.self) private var store
    /// Keeps the workout screen up after finishing, for its summary.
    @State private var finished = false

    var body: some View {
        NavigationStack {
            if store.active != nil || finished {
                WorkoutView(onSummaryClosed: { finished = false })
                    .onAppear { finished = true }
            } else {
                StartChooser(tab: $tab)
            }
        }
    }
}

private struct StartChooser: View {
    @Binding var tab: AppTab
    @Environment(GymStore.self) private var store

    var body: some View {
        let todayIds = store.todayRoutineIds()
        let today = todayIds.compactMap { id in store.routines.first { $0.id == id } }
        let others = store.routines.filter { !todayIds.contains($0.id) }
        let todayName = today.map(\.name).joined(separator: " + ")
        List {
            Section {
                if today.isEmpty {
                    Text("Rest day, but no one’s stopping you.").foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            RoutineIcon(emoji: today[0].emoji, size: 44)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(todayName).font(.title3.weight(.semibold))
                                Text(Fmt.exercises(today.reduce(0) { $0 + $1.ex.count }))
                                    .font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        Button { start(todayIds) } label: {
                            Label("Start \(todayName)", systemImage: "play.fill")
                                .frame(maxWidth: .infinity).fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Today · \(Fmt.weekday(Calendar.current.component(.weekday, from: .now) - 1))")
            }
            if !others.isEmpty {
                Section("Other routines") {
                    ForEach(others) { r in
                        Button { start([r.id]) } label: {
                            HStack(spacing: 12) {
                                RoutineIcon(emoji: r.emoji)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(r.name).foregroundStyle(.primary)
                                    Text(Fmt.exercises(r.ex.count)).font(.subheadline).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("Start").font(.subheadline.weight(.semibold)).foregroundStyle(Color.accentColor)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Section {
                Button { start([]) } label: {
                    Label("Freestyle workout (pick as you go)", systemImage: "shuffle")
                }
                if store.routines.isEmpty {
                    Button { tab = .plan } label: { Label("Build a plan first", systemImage: "calendar") }
                }
            }
        }
        .navigationTitle("Start workout")
    }

    private func start(_ ids: [String]) {
        store.beginWorkout(routineIds: ids, bodyWeight: nil, freestyleName: String(localized: "Freestyle"))
    }
}
