import OpenGymCore
import SwiftUI

/// openGym's Stats tab, the analytics hub: the tiles, the year of activity, exercise progress,
/// effort, structural balance and the latest workouts. Its stack reaches the same screens as
/// Today's (history, a workout, an exercise), with a router of its own.
struct StatsView: View {
    @Binding var tab: AppTab
    @Environment(GymStore.self) private var store
    @State private var router = TodayRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            StatsHome()
                .navigationDestination(for: TodayRouter.Route.self) { route in RouteDestination(route: route) }
        }
        .sheet(item: $router.sheet) { sheet in TodaySheetView(sheet: sheet) }
        .environment(router)
        .onAppear {
            router.openTab = { tab = $0 }
            if router.path.isEmpty { router.path = DebugLaunch.statsPath }
        }
        // A workout opened in the editor (or a past one being logged) runs on the Today tab.
        .onChange(of: store.active?.id) { _, id in
            if id != nil, tab == .stats { router.path = []; tab = .today }
        }
    }
}

private struct StatsHome: View {
    @Environment(GymStore.self) private var store
    @Environment(TodayRouter.self) private var router

    var body: some View {
        let o = store.statsOverview(today: Day.today)
        List {
            if let o {
                Section {
                    tiles(o)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
                if let map = store.heatmap() {
                    Section(map.title) {
                        HeatmapView(map: map, onMetric: { store.setHeatmapMetric($0) }, onDay: open)
                    }
                }
                progress(o)
                if o.hasEffort {
                    Section { EffortCardView() }
                }
                if o.workouts > 0 {
                    Section {
                        NavigationLink(value: TodayRouter.Route.balance) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Structural balance")
                                Text("See which lift is holding back the rest.").font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        .accessibilityIdentifier("stats.balance")
                    }
                    Section {
                        ForEach(o.recent) { row in
                            NavigationLink(value: TodayRouter.Route.workout(row.key)) { WorkoutRowView(row: row) }
                        }
                    } header: {
                        HStack {
                            Text("Recent workouts")
                            Spacer()
                            Button { router.path.append(.history) } label: {
                                HStack(spacing: 2) { Text(o.all); Image(systemName: "chevron.forward") }
                            }
                            .font(.subheadline)
                            .textCase(nil)
                            .accessibilityIdentifier("stats.allWorkouts")
                        }
                    }
                }
            }
        }
        .navigationTitle("Stats")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { router.path.append(.history) } label: { Image(systemName: "clock.arrow.circlepath") }
                    .accessibilityLabel(Text("History"))
            }
        }
    }

    private func tiles(_ o: StatsOverview) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            Tile(id: "workouts", title: "Workouts", symbol: "dumbbell.fill", value: "\(o.workouts)")
            Tile(id: "month", title: "This month", symbol: "calendar", value: "\(o.month)")
            Tile(id: "streak", title: "Week streak", symbol: "flame.fill", value: "\(o.streak)")
            Tile(id: "weight", title: "Weight 30d", symbol: "scalemass.fill", value: o.weight, tint: Self.tone(o.tone))
        }
    }

    @ViewBuilder
    private func progress(_ o: StatsOverview) -> some View {
        let list = store.progressExercises()
        Section {
            if list.isEmpty {
                Text(o.empty).font(.subheadline).foregroundStyle(.secondary)
            } else {
                if let first = list.first, let p = store.exerciseProgress(first.id), p.top.count > 1 {
                    NavigationLink(value: TodayRouter.Route.progress(first.id)) {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(p.name).fontWeight(.semibold)
                                Spacer()
                                Text(p.best.top).foregroundStyle(Color.accentColor).monospacedDigit()
                            }
                            ProgressChart(points: p.top, unit: p.unit, height: 110)
                                .allowsHitTesting(false)
                        }
                    }
                }
                ForEach(list.prefix(4)) { e in
                    NavigationLink(value: TodayRouter.Route.progress(e.id)) {
                        HStack {
                            Text(e.name)
                            Spacer(minLength: 8)
                            if let v = e.value { Text(v).foregroundStyle(.secondary).monospacedDigit() }
                        }
                    }
                }
                NavigationLink(value: TodayRouter.Route.progressPicker) {
                    Label("All exercises", systemImage: "magnifyingglass")
                }
                .accessibilityIdentifier("stats.progressPicker")
            }
        } header: {
            Text("Exercise progress")
        }
    }

    /// A day on the heatmap: its one workout, or the calendar when there were several.
    private func open(_ day: HeatCell) {
        let keys = store.workouts(on: day.iso).map(\.id)
        if keys.count == 1 { router.path.append(.workout(keys[0])) } else { router.sheet = .calendar }
    }

    static func tone(_ tone: String) -> Color {
        switch tone {
        case "good": .accentColor
        case "bad": .red
        case "plain": .primary
        default: .secondary
        }
    }
}

/// One of the Stats tiles: a label with its symbol over a big number.
private struct Tile: View {
    let id: String
    let title: LocalizedStringKey
    let symbol: String
    let value: String
    var tint: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(value)
                .font(.title.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("stats.tile.\(id)")
    }
}
