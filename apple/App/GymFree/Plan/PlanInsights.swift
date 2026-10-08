import OpenGymCore
import SwiftUI

// Plan intelligence (apple/core/insights.js): routine time and difficulty, optional fixes, a
// cool-down, and "Improve my plan". The engine decides everything; these views only show it
// and hand a tapped suggestion straight back.

/// Time and difficulty of one routine, for the Plan list (insights.routineSummaries).
struct RoutineSummary: Decodable, Hashable {
    var min: Int
    var level: String?
}

/// The planned week added up (insights.weekSummary).
struct WeekTotal: Decodable, Hashable {
    var min: Int
    var sessions: Int
    var days: [Int]
}

struct Difficulty: Decodable, Hashable {
    struct Over: Decodable, Hashable { var muscle: String; var sets: Double }
    var level: String?
    var score: Int
    var sets: Int
    var exercises: Int
    var minutes: Int
    var over: [Over]
    var tooMuch: Bool
    var tooLittle: Bool
}

/// One optional change from the engine; `raw` goes back to `applySuggestion` as it came.
struct PlanSuggestion: Identifiable, Hashable {
    struct Body: Decodable, Hashable {
        var id: String
        var type: String
        var group: String?
        var rid: String?
        var ex: [GeneratedPlan.Exercise]?
        var muscle: String?
        var muscles: [String]?
        var focus: String?
        var name: String?
        var days: [Int]?
        var day: Int?
        var routineName: String?
        var issue: String?
        var by: String?
        var moveRegion: String?
        var exId: String?
        var from: Int?
        var to: Int?
        var indexes: [Int]?
        var minutes: JSONValue?
    }

    let raw: JSONValue
    let body: Body
    var id: String { body.id }
    /// Minutes as one number; a split's two halves come as a pair.
    var minutes: [Int] {
        switch body.minutes {
        case .number(let n): [Int(n)]
        case .array(let a): a.compactMap { $0.number.map(Int.init) }
        default: []
        }
    }

    init?(_ raw: JSONValue?) {
        guard let raw, case .object = raw, let data = try? JSONEncoder().encode(raw),
              let body = try? JSONDecoder().decode(Body.self, from: data) else { return nil }
        self.raw = raw
        self.body = body
    }

    static func == (l: PlanSuggestion, r: PlanSuggestion) -> Bool { l.raw == r.raw }
    func hash(into h: inout Hasher) { h.combine(raw) }
}

struct RoutineInsights {
    var minutes: Int
    var difficulty: Difficulty?
    var suggestions: [PlanSuggestion]
    var cooldown: PlanSuggestion?

    init(_ raw: JSONValue) {
        minutes = raw["minutes"]?.number.map(Int.init) ?? 0
        difficulty = raw["difficulty"].flatMap { try? JSONDecoder().decode(Difficulty.self, from: JSONEncoder().encode($0)) }
        if case .array(let list) = raw["suggestions"] { suggestions = list.compactMap { PlanSuggestion($0) } } else { suggestions = [] }
        cooldown = PlanSuggestion(raw["cooldown"])
    }
}

struct PlanCheck: Decodable, Hashable, Identifiable {
    var muscle: String
    var sets: Double
    var days: Int
    var issue: String
    var id: String { muscle }
}

extension GymStore {
    func routineSummaries() -> [String: RoutineSummary] {
        query("insights", "routineSummaries", as: [String: RoutineSummary].self) ?? [:]
    }

    func weekTotal() -> WeekTotal? { query("insights", "weekSummary", as: WeekTotal.self) }

    func routineInsights(_ id: String) -> RoutineInsights? {
        query("insights", "routineInsights", [id], as: JSONValue.self).map(RoutineInsights.init)
    }

    /// `(checks, suggestions)` for the planned week (insights.improvePlan).
    func improvePlan() -> (checks: [PlanCheck], suggestions: [PlanSuggestion]) {
        guard let raw = query("insights", "improvePlan", as: JSONValue.self) else { return ([], []) }
        let checks = raw["checks"].flatMap { try? JSONDecoder().decode([PlanCheck].self, from: JSONEncoder().encode($0)) } ?? []
        var suggestions: [PlanSuggestion] = []
        if case .array(let list) = raw["suggestions"] { suggestions = list.compactMap { PlanSuggestion($0) } }
        return (checks, suggestions)
    }

    /// Applies a suggestion; `name` names a routine it creates. Returns the routine changed or made.
    @discardableResult
    func applySuggestion(_ s: PlanSuggestion, name: String? = nil) -> String? {
        perform("insights", "applySuggestion", [s.raw.any, name ?? NSNull()], as: String?.self) ?? nil
    }

    func dismissInsight(_ routineId: String, _ group: String) {
        perform("insights", "dismissInsight", [routineId, group], as: Bool.self)
    }
}

extension Fmt {
    /// "45 min", "1 h 20 min".
    static func duration(_ minutes: Int) -> String {
        let h = minutes / 60, m = minutes % 60
        if h == 0 { return String(localized: "\(m) min") }
        return m == 0 ? String(localized: "\(h) h") : String(localized: "\(h) h \(m) min")
    }

    static func difficulty(_ level: String?) -> String? {
        switch level {
        case "light": String(localized: "Light")
        case "moderate": String(localized: "Moderate")
        case "hard": String(localized: "Hard")
        case "veryHard": String(localized: "Very hard")
        default: nil
        }
    }

    static func difficultyColor(_ level: String?) -> Color {
        switch level {
        case "light": .teal
        case "moderate": .blue
        case "hard": .orange
        default: .red
        }
    }
}

/// "6 exercises · 45 min · Moderate": a routine row's second line.
struct RoutineSubtitle: View {
    let exercises: Int
    let summary: RoutineSummary?

    var body: some View {
        // One line when it fits, else the time and difficulty under the exercise count.
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 4) {
                Text(Fmt.exercises(exercises))
                if summary.map({ $0.min > 0 }) == true { Text("·"); timing }
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(Fmt.exercises(exercises))
                if summary.map({ $0.min > 0 }) == true { HStack(spacing: 4) { timing } }
            }
        }
        .lineLimit(1)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("routine.summary")
    }

    @ViewBuilder private var timing: some View {
        if let s = summary {
            Text(Fmt.duration(s.min))
            if let label = Fmt.difficulty(s.level) {
                Text("·")
                Text(label).foregroundStyle(Fmt.difficultyColor(s.level))
            }
        }
    }
}

/// The routine editor's line under the name: time, difficulty, hard sets.
struct RoutineStatsLine: View {
    let insights: RoutineInsights

    var body: some View {
        HStack(spacing: 4) {
            Text(String(localized: "About \(Fmt.duration(insights.minutes))"))
            if let d = insights.difficulty, let label = Fmt.difficulty(d.level) {
                Text("·")
                Text(label).foregroundStyle(Fmt.difficultyColor(d.level))
                Text("·")
                Text("\(d.sets) hard sets")
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .lineLimit(1)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("routine.stats")
    }
}

/// The routine editor's optional suggestions: a fix when the session is a lot or very little,
/// and a cool-down. Each is one tap to apply and can be dismissed for this routine.
struct RoutineSuggestionsSection: View {
    let routineId: String
    let insights: RoutineInsights
    @Environment(GymStore.self) private var store
    @Environment(ExerciseCatalog.self) private var catalog

    var body: some View {
        let fixes = insights.suggestions
        if !fixes.isEmpty || insights.cooldown != nil {
            Section {
                if let group = fixes.first?.body.group, let d = insights.difficulty {
                    HStack(alignment: .firstTextBaseline) {
                        Label(group == "tooMuch" ? headline(d) : String(localized: "A light session: fewer than 6 hard sets."),
                              systemImage: group == "tooMuch" ? "exclamationmark.circle" : "leaf")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 4)
                        dismissButton(group)
                    }
                    ForEach(fixes) { s in row(s) }
                }
                if let cd = insights.cooldown { row(cd, dismissible: true) }
            } header: {
                Text("Suggestions")
            } footer: {
                Text("Optional. Dismissed suggestions stay hidden for this routine.")
            }
        }
    }

    private func headline(_ d: Difficulty) -> String {
        if let o = d.over.first {
            return String(localized: "\(catalog.muscleName(o.muscle)) gets \(Fmt.num(o.sets, decimals: 0)) sets in one session; past about 10, more add little.")
        }
        if d.exercises > 8 { return String(localized: "\(d.exercises) exercises is a lot for one session.") }
        return String(localized: "About \(Fmt.duration(d.minutes)) and \(d.sets) hard sets: a long session.")
    }

    private func dismissButton(_ group: String) -> some View {
        Button { withAnimation { store.dismissInsight(routineId, group) } } label: {
            Image(systemName: "xmark").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(Text("Dismiss"))
        .accessibilityIdentifier("insight.dismiss.\(group)")
    }

    @ViewBuilder
    private func row(_ s: PlanSuggestion, dismissible: Bool = false) -> some View {
        let text = SuggestionText(s, catalog: catalog)
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: text.icon).foregroundStyle(.tint).frame(width: 22)
            VStack(alignment: .leading, spacing: 2) {
                Text(text.title).font(.subheadline.weight(.semibold))
                if !text.detail.isEmpty { Text(text.detail).font(.caption).foregroundStyle(.secondary) }
            }
            Spacer(minLength: 4)
            Button(text.action) {
                withAnimation { _ = store.applySuggestion(s, name: SuggestionText.routineName(s, store: store)) }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .accessibilityIdentifier("insight.apply.\(s.body.type)")
            if dismissible, let group = s.body.group { dismissButton(group) }
        }
    }
}

/// What a suggestion says, in the device language.
struct SuggestionText {
    var icon: String
    var title: String
    var detail: String
    var action: String

    @MainActor
    init(_ s: PlanSuggestion, catalog: ExerciseCatalog) {
        let b = s.body
        let names = (b.ex ?? []).map { catalog.name($0.id) }
        let muscle = b.muscle.map { catalog.muscleName($0) } ?? ""
        switch b.type {
        case "split":
            icon = "square.split.2x1"
            title = String(localized: "Split into two routines")
            let m = s.minutes
            let halves = m.count == 2 ? String(localized: "about \(m[0]) and \(m[1]) min") : ""
            let how = b.by == "upperLower" ? String(localized: "Upper and lower body, \(halves)") : String(localized: "Two halves, \(halves)")
            detail = b.day.map { how + String(localized: "; the new one on \(Fmt.weekday($0))") } ?? how
            action = String(localized: "Split")
        case "dropSet":
            icon = "minus.circle"
            title = String(localized: "Drop a set from \(catalog.name(b.exId ?? ""))")
            detail = String(localized: "\(b.from ?? 0) → \(b.to ?? 0) sets")
            action = String(localized: "Drop")
        case "addSets":
            icon = "plus.circle"
            title = String(localized: "Add a set to each exercise")
            detail = String(localized: "More sets build more; about 10 a week per muscle is a good target.")
            action = String(localized: "Add")
        case "addExercise":
            icon = "plus.circle"
            title = String(localized: "Add an exercise for \(muscle)")
            detail = zip(names, b.ex ?? []).map { "\($0) · \(PlanPreviewView.prescription($1))" }.joined(separator: "\n")
            action = String(localized: "Add")
        case "cooldown":
            icon = "figure.cooldown"
            title = String(localized: "Add a cool-down stretch")
            detail = names.joined(separator: ", ") + " · " + String(localized: "about \(s.minutes.first ?? 3) min, after lifting")
            action = String(localized: "Add")
        case "addRoutine":
            icon = "calendar.badge.plus"
            let days = (b.days ?? []).map { Fmt.weekday($0, short: true) }.joined(separator: "/")
            title = String(localized: "Add a \(Self.focusName(b.focus).lowercased()) routine (\(names.count) exercises, ~\(s.minutes.first ?? 15) min) on \(days)")
            detail = String(localized: "For \((b.muscles ?? []).map { catalog.muscleName($0) }.formatted(.list(type: .and))), twice a week.")
            action = String(localized: "Add")
        case "appendExercises":
            icon = "text.badge.plus"
            title = names.count == 1
                ? String(localized: "Add an exercise for \(muscle) to \(b.routineName ?? "")")
                : String(localized: "Add \(names.count) exercises for \(muscle) to \(b.routineName ?? "")")
            detail = b.issue == "once"
                ? String(localized: "\(muscle) is trained on one day only; twice a week is better. About \(s.minutes.first ?? 5) min more.")
                : String(localized: "\(muscle) gets little work this week. About \(s.minutes.first ?? 5) min more.")
            action = String(localized: "Add")
        default:
            icon = "lightbulb"
            title = b.type
            detail = ""
            action = String(localized: "Apply")
        }
    }

    static func focusName(_ focus: String?) -> String {
        switch focus {
        case "core": String(localized: "Core")
        case "lower": String(localized: "Legs")
        case "upper": String(localized: "Upper body")
        default: String(localized: "Extra work")
        }
    }

    /// The localised name for a routine a suggestion creates (nil keeps the engine's).
    @MainActor
    static func routineName(_ s: PlanSuggestion, store: GymStore) -> String? {
        switch s.body.type {
        case "addRoutine": return focusName(s.body.focus)
        case "split":
            guard let r = store.routines.first(where: { $0.id == s.body.rid }) else { return nil }
            switch s.body.moveRegion {
            case "lower": return "\(r.name) · \(String(localized: "Lower body"))"
            case "upper": return "\(r.name) · \(String(localized: "Upper body"))"
            default: return "\(r.name) · 2"
            }
        default: return nil
        }
    }
}

/// "Improve my plan": what the week is short of or over, and a couple of optional fixes,
/// each with its exercises and one button to add it.
struct ImprovePlanSheet: View {
    @Environment(GymStore.self) private var store
    @Environment(ExerciseCatalog.self) private var catalog
    @Environment(\.dismiss) private var dismiss
    @State private var checks: [PlanCheck] = []
    @State private var suggestions: [PlanSuggestion] = []
    @State private var added: Set<String> = []
    @State private var loaded = false

    var body: some View {
        NavigationStack {
            List {
                if loaded && checks.isEmpty && suggestions.isEmpty {
                    Section {
                        Label("Every major muscle gets enough work, at least twice a week.", systemImage: "checkmark.seal")
                    }
                }
                ForEach(suggestions) { s in
                    let text = SuggestionText(s, catalog: catalog)
                    Section {
                        ForEach(Array((s.body.ex ?? []).enumerated()), id: \.offset) { _, e in
                            HStack(spacing: 12) {
                                ExerciseThumb(exerciseId: e.id, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(catalog.name(e.id))
                                    Text(PlanPreviewView.prescription(e)).font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                        if added.contains(s.id) {
                            Label("Added", systemImage: "checkmark.circle.fill").foregroundStyle(.green)
                        } else {
                            Button {
                                store.applySuggestion(s, name: SuggestionText.routineName(s, store: store))
                                added.insert(s.id)
                                checks = store.improvePlan().checks
                            } label: {
                                Label(text.action, systemImage: "plus").frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .accessibilityIdentifier("improve.add.\(s.id)")
                        }
                    } header: {
                        Text(text.title).textCase(nil).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                    } footer: {
                        Text(text.detail)
                    }
                }
                if !checks.isEmpty {
                    Section {
                        ForEach(checks) { c in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(catalog.muscleName(c.muscle))
                                Text(Self.checkText(c)).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    } header: { Text("Your week") } footer: {
                        Text("Counted in sets a week (a set for a helping muscle counts less). Research: about 4 sets a week is the least that builds a muscle, 10–20 builds most, over 20 rarely adds more, and twice a week beats once.")
                    }
                }
            }
            .navigationTitle("Improve my plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .onAppear {
                guard !loaded else { return }
                (checks, suggestions) = store.improvePlan()
                loaded = true
            }
        }
        .presentationDetents([.medium, .large])
    }

    static func checkText(_ c: PlanCheck) -> String {
        let sets = Fmt.num(c.sets, decimals: 0)
        switch c.issue {
        case "low": return String(localized: "\(sets) sets a week: little or no work.")
        case "high": return String(localized: "\(sets) sets a week: more than 20 rarely adds anything.")
        default: return String(localized: "\(sets) sets a week, all on one day: twice a week is better.")
        }
    }
}
