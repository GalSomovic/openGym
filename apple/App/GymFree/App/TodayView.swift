import OpenGymCore
import SwiftUI

/// openGym's Home and start screen: the week, today's plan, body weight, history, the other
/// routines and freestyle. A running session takes the whole tab.
struct TodayView: View {
    @Binding var tab: AppTab
    @Environment(GymStore.self) private var store
    /// Keeps the workout screen up after finishing, for its summary.
    @State private var finished = false
    @State private var router = TodayRouter()

    var body: some View {
        NavigationStack(path: $router.path) {
            Group {
                if store.active != nil || finished {
                    WorkoutView(onSummaryClosed: { finished = false })
                        .onAppear { finished = true }
                } else {
                    StartChooser()
                }
            }
            .navigationDestination(for: TodayRouter.Route.self) { route in RouteDestination(route: route) }
        }
        .overlay(alignment: .top) { if store.active == nil && !finished { ToastView() } }
        .sheet(item: $router.sheet) { sheet in
            TodaySheetView(sheet: sheet)
        }
        .environment(router)
        .onAppear { router.openTab = { tab = $0 } }
        // A session started from History (a past workout, an edit) takes the tab from the top.
        .onChange(of: store.active?.id) { _, id in if id != nil { router.path = [] } }
        // An edit saved or dropped goes back to the history it came from.
        .onChange(of: store.active?.editingWorkoutId) { old, new in
            if old != nil, new == nil { router.path = [.history] }
        }
    }
}

/// Where a route of the Today and Stats stacks goes.
struct RouteDestination: View {
    let route: TodayRouter.Route

    var body: some View {
        switch route {
        case .history: HistoryView()
        case .workout(let key): WorkoutDetailView(key: key)
        case .weight: WeightView()
        case .exercise(let id): ExerciseDetailView(exerciseId: id)
        case .progress(let id): ExerciseProgressView(exerciseId: id)
        case .progressPicker: ProgressPickerView()
        case .balance: StructuralBalanceView()
        }
    }
}

/// The sheets over the Today (and Stats) tab, one at a time.
struct TodaySheetView: View {
    let sheet: TodayRouter.Sheet

    var body: some View {
        switch sheet {
        case .day(let iso): DayOverrideSheet(iso: iso)
        case .logPast(let initial): LogPastWorkoutSheet(initial: initial)
        case .calendar: CalendarSheet()
        case .weighIn(let ids): WeighInSheet(mode: .beforeWorkout(ids))
        case .logWeight: WeighInSheet(mode: .log)
        case .goal: WeightGoalSheet()
        }
    }
}

private struct StartChooser: View {
    @Environment(GymStore.self) private var store
    @Environment(TodayRouter.self) private var router
    @State private var weekOffset = 0

    var body: some View {
        let todayISO = Day.today
        let info = store.todayInfo(todayISO)
        let todayIds = info?.routineIds ?? store.todayRoutineIds()
        let today = todayIds.compactMap { id in store.routines.first { $0.id == id } }
        let others = store.routines.filter { !todayIds.contains($0.id) }
        let todayName = today.map(\.name).joined(separator: " + ")
        let card = store.weightCard()
        List {
            Section {
                WeekStripView(offset: $weekOffset)
            }
            Section {
                if let done = info?.done {
                    Button { router.show(.workout(done.key)) } label: {
                        Label {
                            Text(done.name).foregroundStyle(.primary)
                        } icon: {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                        }
                    }
                }
                if today.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Rest day, but no one’s stopping you.").foregroundStyle(.secondary)
                        if let next = info?.next {
                            Text(next).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            RoutineIcon(emoji: today[0].emoji, size: 44)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(todayName).font(.title3.weight(.semibold))
                                HStack(spacing: 6) {
                                    Text(Fmt.exercises(today.reduce(0) { $0 + $1.ex.count }))
                                    if info?.rescheduled == true {
                                        Text("· rescheduled").foregroundStyle(.orange)
                                    }
                                }
                                .font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                        // Once today's session is logged it is no longer urged (openGym #4), but
                        // a second session stays one tap away.
                        if info?.done == nil {
                            Button { start(todayIds) } label: {
                                Label("Start \(todayName)", systemImage: "play.fill")
                                    .frame(maxWidth: .infinity).fontWeight(.semibold)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        } else {
                            Button { start(todayIds) } label: {
                                Label("Start \(todayName)", systemImage: "play.fill").frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Today · \(Fmt.weekday(Calendar.current.component(.weekday, from: .now) - 1))")
            }
            Section {
                Button { router.show(.history) } label: {
                    LinkRow(symbol: "clock.arrow.circlepath", tint: .accentColor, title: Text("History"),
                            subtitle: store.historyCount(), trailing: "chevron.forward")
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("today.history")
                if let streak = store.streak(todayISO) {
                    Button { router.sheet = .calendar } label: {
                        LinkRow(symbol: "flame.fill", tint: .orange, title: Text(streak.title),
                                subtitle: streak.line, trailing: "calendar")
                    }
                    .buttonStyle(.plain)
                }
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
                    Button { router.openTab(.plan) } label: { Label("Build a plan first", systemImage: "calendar") }
                }
            }
            if let card, card.show {
                Section { WeightCardView(card: card) }
            }
            if store.nutritionTargets?.kcal != nil {
                Section { FoodTodayCard() }
            }
        }
        .navigationTitle("Start workout")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { router.sheet = .calendar } label: { Image(systemName: "calendar") }
                    .accessibilityLabel(Text("Calendar"))
            }
        }
    }

    /// sheets.jsx startFlow: the weigh-in first when it is on (Settings), skippable.
    private func start(_ ids: [String]) {
        if store.weightCard()?.weighIn ?? true {
            router.sheet = .weighIn(ids)
        } else {
            store.beginWorkout(routineIds: ids, bodyWeight: nil, freestyleName: String(localized: "Freestyle"))
        }
    }
}

/// A row that opens something: an icon, a title over a detail, and where it leads.
struct LinkRow: View {
    let symbol: String
    let tint: Color
    let title: Text
    let subtitle: String
    let trailing: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).foregroundStyle(tint).frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                title.foregroundStyle(.primary)
                Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: trailing).font(.footnote.weight(.semibold)).foregroundStyle(.tertiary)
        }
        .contentShape(Rectangle())
    }
}
