import OpenGymCore
import SwiftUI

/// openGym's Plan screen: the week, then the routines.
struct PlanView: View {
    @Environment(GymStore.self) private var store
    @Environment(ExerciseCatalog.self) private var catalog
    @State private var path = NavigationPath()
    @State private var starterPresented = false
    @State private var builderPresented = false
    @State private var sharePresented = false
    @State private var deleting: Routine?
    @State private var reordering = false

    private var weekStart: Int { Int(store.pick("weekStart", as: Double.self) ?? 1) }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                if store.routines.isEmpty {
                    Section {
                        // Not ContentUnavailableView: on iOS 26 it squeezes its action buttons into
                        // a narrow column, hiding their titles.
                        VStack(spacing: 14) {
                            Image(systemName: "list.clipboard").font(.system(size: 40)).foregroundStyle(.secondary)
                            Text("No routines yet").font(.title3.bold())
                            Text("Build your own, or start from a plan and change anything you like.")
                                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                            VStack(spacing: 10) {
                                Button { newRoutine() } label: {
                                    Label("New routine", systemImage: "plus").frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                Button { builderPresented = true } label: {
                                    Label("Make me a plan", systemImage: "wand.and.stars").frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                                Button { starterPresented = true } label: {
                                    Label("Starter plans", systemImage: "sparkles").frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            }
                            .controlSize(.large)
                            .padding(.top, 4)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                }
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
                                Spacer(minLength: 8)
                                // What the routine trains, at a glance; the editor has the full map.
                                if !r.ex.isEmpty, let m = store.routineMuscles(r.id), !m.worked.isEmpty {
                                    BodyMapView(levels: m.levels)
                                        .frame(width: 64, height: 54)
                                        .accessibilityHidden(true)
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
                    HStack(spacing: 16) {
                        Text("Routines")
                        Spacer()
                        if store.routines.count > 1 {
                            Button(reordering ? "Done" : "Reorder") { withAnimation { reordering.toggle() } }
                                .font(.subheadline.weight(reordering ? .semibold : .regular))
                                .textCase(nil)
                        }
                        Button("New", systemImage: "plus") { newRoutine() }
                            .font(.subheadline)
                            .textCase(nil)
                    }
                }
                if let week = store.query("plan", "weekMuscles", as: RoutineMuscles.self), !week.worked.isEmpty {
                    let gaps = (store.bodyInfo()?.muscles ?? []).filter { (week.levels[$0.slug] ?? 0) <= 1 }.map(\.name)
                    Section {
                        BodyMapView(levels: week.levels)
                            .frame(maxHeight: 160)
                            .padding(.vertical, 2)
                        FlowTags(tags: week.worked.prefix(6).map { catalog.muscleName($0) })
                        if !gaps.isEmpty {
                            Label {
                                Text("Little or no work: \(gaps.formatted(.list(type: .and)))")
                            } icon: { Image(systemName: "exclamationmark.circle").foregroundStyle(.orange) }
                            .font(.footnote)
                        }
                    } header: { Text("What your plan covers") } footer: {
                        Text("Every planned day added up; darker is more sets.")
                    }
                }
            }
            .navigationTitle("Plan")
            .environment(\.editMode, .constant(reordering ? .active : .inactive))
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { newRoutine() } label: { Image(systemName: "plus") }
                        .accessibilityLabel(Text("New routine"))
                }
                if !store.routines.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button("Make me a plan", systemImage: "wand.and.stars") { builderPresented = true }
                            Button("Starter plans", systemImage: "sparkles") { starterPresented = true }
                            Button("Share plan", systemImage: "square.and.arrow.up") { sharePresented = true }
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
            .sheet(isPresented: $builderPresented) { PlanBuilderView() }
            .sheet(isPresented: $sharePresented) { PlanShareSheet() }
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
    @State private var presets: [Preset] = []

    struct Preset: Decodable, Identifiable { var id: String; var name: String; var days: Int; var minutes: Int; var plan: JSONValue }

    var body: some View {
        NavigationStack {
            List {
                if !presets.isEmpty {
                    Section {
                        ForEach(presets) { p in
                            if let plan = GeneratedPlan(p.plan) {
                                NavigationLink {
                                    PlanPreviewView(plan: plan) { dismiss() }
                                } label: {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(p.name)
                                        Text("\(p.days) days per week · about \(p.minutes) min · \(Self.presetAbout(p.id))")
                                            .font(.subheadline).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    } header: { Text("Evidence-based") } footer: {
                        Text("Built from independent research reviews, filled with exercises for the equipment in Settings.")
                    }
                }
                Section("openGym classics") {
            ForEach(store.starterPlans()) { plan in
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
                }
            }
            .onAppear {
                let eq = PlanAnswers(equipment: store.equipment()).equipment
                presets = store.query("planner", "presetList", [eq], as: [Preset].self) ?? []
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

    static func presetAbout(_ id: String) -> String {
        switch id {
        case "P01": String(localized: "an easy start")
        case "P02", "P04", "P05": String(localized: "the whole body each time")
        case "P06": String(localized: "upper and lower body twice each")
        case "P08": String(localized: "heavy main lifts")
        case "P09": String(localized: "for experienced lifters")
        case "P10": String(localized: "strength plus cardio")
        case "P11": String(localized: "strength and balance")
        case "P12": String(localized: "the least that works")
        default: ""
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
