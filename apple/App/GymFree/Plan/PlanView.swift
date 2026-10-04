import OpenGymCore
import SwiftUI

/// openGym's Plan screen: the week, then the routines.
struct PlanView: View {
    @Environment(GymStore.self) private var store
    @State private var path = NavigationPath()
    @State private var starterPresented = false
    @State private var deleting: Routine?

    private var weekStart: Int { Int(store.pick("weekStart", as: Double.self) ?? 1) }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section("Week schedule") {
                    let week = store.week
                    ForEach(Fmt.weekOrder(start: weekStart), id: \.self) { day in
                        WeekdayRow(day: day, routineIds: week[String(day)] ?? [])
                    }
                }
                Section {
                    ForEach(store.routines) { r in
                        NavigationLink(value: r.id) {
                            HStack(spacing: 12) {
                                RoutineIcon(emoji: r.emoji)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(r.name)
                                    Text(Fmt.exercises(r.ex.count)).font(.subheadline).foregroundStyle(.secondary)
                                }
                            }
                        }
                        .swipeActions {
                            Button("Delete", systemImage: "trash", role: .destructive) { deleting = r }
                        }
                    }
                    .onMove { from, to in
                        guard let source = from.first else { return }
                        let target = to > source ? to - 1 : to
                        if target != source { store.moveRoutine(source, by: target - source) }
                    }
                } header: {
                    HStack {
                        Text("Routines")
                        Spacer()
                        Button("New", systemImage: "plus") { newRoutine() }
                            .font(.subheadline)
                            .textCase(nil)
                    }
                }
                if store.routines.isEmpty {
                    Section {
                        ContentUnavailableView {
                            Label("No routines yet", systemImage: "list.clipboard")
                        } description: {
                            Text("Create one or load a starter plan.")
                        } actions: {
                            Button("Load starter plan", systemImage: "sparkles") { starterPresented = true }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
            .navigationTitle("Plan")
            .toolbar {
                if !store.routines.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button("Load starter plan", systemImage: "sparkles") { starterPresented = true }
                        } label: { Image(systemName: "ellipsis") }
                        .accessibilityLabel(Text("More"))
                    }
                }
            }
            .navigationDestination(for: String.self) { id in RoutineEditorView(routineId: id) }
            .onAppear {
                if let i = DebugLaunch.routine, path.isEmpty, i < store.routines.count { path.append(store.routines[i].id) }
            }
            .sheet(isPresented: $starterPresented) { StarterPlanSheet() }
            .confirmationDialog("Delete routine?", isPresented: Binding(
                get: { deleting != nil }, set: { if !$0 { deleting = nil } }), presenting: deleting) { r in
                Button("Delete", role: .destructive) { store.deleteRoutine(r.id) }
            } message: { r in
                Text("“\(r.name)” and its exercises will be removed.")
            }
        }
    }

    private func newRoutine() {
        if let id = store.addRoutine(name: String(localized: "New routine"), emoji: Glyphs.defaultKey) {
            path.append(id)
        }
    }
}

/// One weekday: rest, or the routines on it with a ＋ for another.
private struct WeekdayRow: View {
    let day: Int
    let routineIds: [String]
    @Environment(GymStore.self) private var store

    private var routines: [Routine] { routineIds.compactMap { id in store.routines.first { $0.id == id } } }

    var body: some View {
        if routines.isEmpty {
            Menu {
                Button("Rest day", systemImage: "moon") { store.assignDay(day, nil) }
                ForEach(store.routines) { r in
                    Button(r.name, systemImage: Glyphs.symbol(r.emoji)) { store.assignDay(day, r.id) }
                }
            } label: {
                HStack {
                    Text(Fmt.weekday(day)).foregroundStyle(.primary)
                    Spacer()
                    Text("Rest").foregroundStyle(.secondary)
                    Image(systemName: "chevron.up.chevron.down").font(.caption).foregroundStyle(.tertiary)
                }
            }
            .tint(.primary)
        } else {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(Fmt.weekday(day))
                    Spacer()
                    Menu {
                        ForEach(store.routines.filter { !routineIds.contains($0.id) }) { r in
                            Button(r.name, systemImage: Glyphs.symbol(r.emoji)) { store.addRoutineToDay(day, r.id) }
                        }
                    } label: {
                        Image(systemName: "plus.circle")
                    }
                    .accessibilityLabel(Text("Add routine"))
                    .disabled(store.routines.count == routineIds.count)
                }
                ForEach(routines) { r in
                    HStack(spacing: 10) {
                        RoutineIcon(emoji: r.emoji, size: 26)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(r.name).font(.subheadline)
                            Text(Fmt.exercises(r.ex.count)).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { store.removeFromDay(day, r.id) } label: {
                            Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("Remove \(r.name) from \(Fmt.weekday(day))"))
                    }
                    .padding(.leading, 6)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

/// The four starter plans; asks before replacing a planned day.
struct StarterPlanSheet: View {
    @Environment(GymStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var confirming: StarterPlan?

    var body: some View {
        NavigationStack {
            List(store.starterPlans()) { plan in
                Button {
                    if store.starterPlanConflicts(plan.id) { confirming = plan } else { load(plan) }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "sparkles").foregroundStyle(.tint).frame(width: 30)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Self.name(plan.id)).foregroundStyle(.primary)
                            Text("\(plan.days) days per week · \(Self.about(plan.id))")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Choose starter plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .confirmationDialog("Load \(confirming.map { Self.name($0.id) } ?? "")?", isPresented: Binding(
                get: { confirming != nil }, set: { if !$0 { confirming = nil } }), titleVisibility: .visible,
                presenting: confirming) { plan in
                Button("Load plan") { load(plan) }
            } message: { plan in
                let days = plan.weekdays.map { Fmt.weekday($0) }.formatted(.list(type: .and))
                Text("The new plan will be scheduled on \(days). Existing routines are kept; only those days of the weekly plan change.")
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func load(_ plan: StarterPlan) {
        store.loadStarterPlan(plan.id)
        dismiss()
    }

    static func name(_ id: String) -> String {
        switch id {
        case "ppl": String(localized: "Push / Pull / Legs")
        case "upper-lower": String(localized: "Upper / Lower")
        case "full-body": String(localized: "Full Body")
        case "5x5": String(localized: "5×5")
        default: id
        }
    }

    static func about(_ id: String) -> String {
        switch id {
        case "ppl": String(localized: "Push, pull and legs each get their own day.")
        case "upper-lower": String(localized: "Upper body twice, lower body twice.")
        case "full-body": String(localized: "Three sessions, the whole body each time.")
        case "5x5": String(localized: "Five sets of five on the main barbell lifts.")
        default: ""
        }
    }
}
