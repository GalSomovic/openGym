import OpenGymCore
import SwiftUI

/// A plan from apple/core/planner.js, decoded for display. `raw` is passed back to apply it.
struct GeneratedPlan: Identifiable {
    struct Safety: Decodable { var level: String; var message: String? }
    struct Exercise: Decodable, Hashable { var id: String; var sets: Int; var mode: String?; var reps: Int?; var repsMin: Int?; var sec: Int?; var sg: String? }
    struct PlanRoutine: Decodable, Identifiable { var key: String; var name: String; var emoji: String?; var ex: [Exercise]; var id: String { key } }
    struct Day: Decodable, Hashable { var day: Int; var key: String }
    struct Cardio: Decodable { var text: String; var steps: Int?; var stepsNote: String? }
    struct Body: Decodable {
        var preset: String; var name: String; var days: Int; var minutes: Int
        var why: [String]; var safety: Safety; var notes: [String]
        var routines: [PlanRoutine]; var schedule: [Day]; var cardio: Cardio
    }

    let raw: JSONValue
    let body: Body
    var id: String { body.preset + body.schedule.map { "\($0.day)" }.joined() }

    init?(_ raw: JSONValue?) {
        guard let raw, let data = try? JSONEncoder().encode(raw),
              let body = try? JSONDecoder().decode(Body.self, from: data) else { return nil }
        self.raw = raw
        self.body = body
    }
}

/// The answers the plan builder asks for (TRAINING.md §13.1). Everything has a default, so
/// "Show my plan" works without touching a single field.
struct PlanAnswers {
    var goal = "muscle"
    var experience = "none"
    var timeOff = "none"
    var days = 3
    var weekdays: Set<Int> = [1, 3, 5]
    var minutes = 45
    var gym = false, dumbbells = false, bench = false, bands = false, bar = false, table = false
    var ageBand = "<40"
    var unsteady = false
    var symptoms = false, condition = false, pregnant = false
    var steps = ""

    var equipment: [String] {
        [gym ? "gym" : nil, dumbbells ? "db" : nil, bench ? "bench" : nil, bands ? "band" : nil,
         bar ? "bar" : nil, table ? "table" : nil].compactMap { $0 }
    }

    var dictionary: [String: Any] {
        var d: [String: Any] = ["goal": unsteady ? "balance" : goal, "experience": experience, "timeOff": timeOff,
                                "days": days, "weekdays": weekdays.sorted(), "minutes": minutes, "equipment": equipment,
                                "ageBand": ageBand, "unsteady": unsteady, "symptoms": symptoms,
                                "condition": condition, "pregnant": pregnant]
        if let s = Int(steps), s > 0 { d["steps"] = s }
        return d
    }

    /// Starts from the equipment chosen in Settings: all of it (no filter) counts as a gym.
    init(equipment: EquipmentState? = nil) {
        guard let e = equipment else { return }
        let has = Set(e.filterOn ? e.selected : e.all)
        gym = !e.filterOn || (has.contains("barbell") && (has.contains("cable") || has.contains("leverage machine")))
        dumbbells = has.contains("dumbbell")
        bands = has.contains("band") || has.contains("resistance band")
        bench = gym
        bar = gym
    }
}

/// "Make me a plan": a short questionnaire, then a preview to add or discard.
struct PlanBuilderView: View {
    @Environment(GymStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var a = PlanAnswers()
    @State private var preview: GeneratedPlan?
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Main goal", selection: $a.goal) {
                        Text("Build muscle").tag("muscle")
                        Text("Get stronger").tag("strength")
                        Text("Lose fat").tag("fatloss")
                        Text("Get healthier, start moving").tag("health")
                        Text("Stay strong and steady").tag("balance")
                    }
                    Picker("Experience", selection: $a.experience) {
                        Text("New, or not in years").tag("none")
                        Text("Up to 6 months").tag("novice")
                        Text("6 months to 2 years").tag("intermediate")
                        Text("More than 2 years").tag("advanced")
                    }
                    if a.experience == "intermediate" || a.experience == "advanced" {
                        Picker("Training right now?", selection: $a.timeOff) {
                            Text("Yes").tag("none")
                            Text("Break under 3 months").tag("short")
                            Text("Break of 3 months or more").tag("long")
                        }
                    }
                } footer: {
                    Text("Every answer has a sensible default; change only what matters to you.")
                }

                Section("Your week") {
                    Stepper("\(a.days) days a week", value: $a.days, in: 2...6)
                        .onChange(of: a.days) { _, n in a.weekdays = Set(Self.defaultDays[n] ?? [1, 3, 5]) }
                    WeekdayPicker(selection: $a.weekdays)
                    Picker("Time per session", selection: $a.minutes) {
                        ForEach([20, 30, 45, 60, 75, 90], id: \.self) { Text("\($0) min").tag($0) }
                    }
                }

                Section {
                    Toggle("Full gym", isOn: $a.gym)
                    if !a.gym {
                        Toggle("Dumbbells", isOn: $a.dumbbells)
                        Toggle("A bench", isOn: $a.bench)
                        Toggle("Resistance bands", isOn: $a.bands)
                        Toggle("Pull-up bar", isOn: $a.bar)
                        Toggle("Sturdy table or low bar to row under", isOn: $a.table)
                    }
                } header: { Text("Equipment") } footer: {
                    Text("With nothing at all you get a bodyweight plan; it builds muscle as well as weights when sets are hard enough.")
                }

                Section {
                    Picker("Age", selection: $a.ageBand) {
                        Text("Under 40").tag("<40")
                        Text("40–59").tag("40-59")
                        Text("60–74").tag("60-74")
                        Text("75 or older").tag("75+")
                    }
                    Toggle("I have fallen in the last year, or feel unsteady", isOn: $a.unsteady)
                    TextField("Daily steps, if you know (optional)", text: $a.steps).keyboardType(.numberPad)
                } header: { Text("About you") }

                Section {
                    Toggle("Chest pain, faintness or unusual breathlessness when active", isOn: $a.symptoms)
                    Toggle("A heart, metabolic or kidney condition", isOn: $a.condition)
                    Toggle("Pregnant or recently gave birth", isOn: $a.pregnant)
                } header: { Text("Health check") } footer: {
                    Text("Answers stay on this phone. They only make the plan gentler and suggest when to check with a doctor; this is not medical advice.")
                }
            }
            .navigationTitle("Make me a plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Show plan") { preview = GeneratedPlan(store.query("planner", "generatePlan", [a.dictionary], as: JSONValue.self)) }
                        .accessibilityIdentifier("planBuilder.show")
                }
            }
            .navigationDestination(item: $preview) { plan in
                PlanPreviewView(plan: plan) { dismiss() }
            }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                a = PlanAnswers(equipment: store.equipment())
            }
        }
    }

    static let defaultDays: [Int: [Int]] = [2: [1, 4], 3: [1, 3, 5], 4: [1, 2, 4, 5], 5: [1, 2, 3, 5, 6], 6: [1, 2, 3, 4, 5, 6]]
}

extension GeneratedPlan: Hashable {
    static func == (l: GeneratedPlan, r: GeneratedPlan) -> Bool { l.raw == r.raw }
    func hash(into h: inout Hasher) { h.combine(raw) }
}

/// Seven toggles, Monday first.
private struct WeekdayPicker: View {
    @Binding var selection: Set<Int>

    var body: some View {
        HStack(spacing: 6) {
            ForEach([1, 2, 3, 4, 5, 6, 0], id: \.self) { day in
                let on = selection.contains(day)
                Button {
                    if on { selection.remove(day) } else { selection.insert(day) }
                } label: {
                    Text(Fmt.weekday(day, short: true))
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background(on ? Color.accentColor : Color.secondary.opacity(0.15), in: .rect(cornerRadius: 8))
                        .foregroundStyle(on ? .white : .primary)
                }
                .buttonStyle(.borderless)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}

/// What a plan contains and why, with one button to add it.
struct PlanPreviewView: View {
    let plan: GeneratedPlan
    var onAdded: () -> Void
    @Environment(GymStore.self) private var store
    @Environment(ExerciseCatalog.self) private var catalog
    @State private var conflicts: [Int] = []
    @State private var confirming = false

    var body: some View {
        List {
            if let message = plan.body.safety.message {
                Section {
                    Label(message, systemImage: plan.body.safety.level == "stop" ? "exclamationmark.triangle.fill" : "stethoscope")
                        .foregroundStyle(plan.body.safety.level == "stop" ? .red : .orange)
                }
            }
            Section("Why this plan") {
                ForEach(plan.body.why + plan.body.notes, id: \.self) { Text($0).font(.subheadline) }
            }
            Section("Week") {
                ForEach(plan.body.schedule, id: \.self) { d in
                    LabeledContent(Fmt.weekday(d.day), value: plan.body.routines.first { $0.key == d.key }?.name ?? d.key)
                }
            }
            ForEach(plan.body.routines) { r in
                Section(r.name) {
                    ForEach(r.ex, id: \.self) { e in
                        HStack(spacing: 12) {
                            ExerciseThumb(exerciseId: e.id, size: 40)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(catalog.name(e.id))
                                Text(Self.prescription(e)).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            Section("Cardio and steps") {
                Text(plan.body.cardio.text).font(.subheadline)
                if let s = plan.body.cardio.stepsNote { Text(s).font(.subheadline) }
            }
        }
        .navigationTitle(plan.body.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button {
                conflicts = store.query("planner", "planConflicts", [plan.raw.any], as: [Int].self) ?? []
                if conflicts.isEmpty { add() } else { confirming = true }
            } label: {
                Text("Add to my plan").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding()
            .background(.bar)
            .accessibilityIdentifier("planPreview.add")
        }
        .confirmationDialog("Replace planned days?", isPresented: $confirming, titleVisibility: .visible) {
            Button("Add plan") { add() }
        } message: {
            Text("\(conflicts.map { Fmt.weekday($0) }.formatted(.list(type: .and))) will get the new routines. Your existing routines are kept.")
        }
    }

    private func add() {
        store.perform("planner", "applyPlan", [plan.raw.any], as: [String].self)
        onAdded()
    }

    static func prescription(_ e: GeneratedPlan.Exercise) -> String {
        let superset = e.sg != nil ? String(localized: " · superset") : ""
        if e.mode == "time" { return String(localized: "\(e.sets) × \(e.sec ?? 30) s") + superset }
        return String(localized: "\(e.sets) × \(e.repsMin ?? e.reps ?? 10)–\(e.reps ?? 10) reps") + superset
    }
}
