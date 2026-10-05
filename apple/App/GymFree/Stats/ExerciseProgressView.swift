import OpenGymCore
import SwiftUI

/// Stats.jsx's exercise picker: every exercise you have logged, strongest first, searchable the
/// way openGym's picker searches.
struct ProgressPickerView: View {
    @Environment(GymStore.self) private var store
    @State private var query = ""

    var body: some View {
        let list = store.progressExercises(query)
        List {
            if list.isEmpty {
                ContentUnavailableView(query.isEmpty ? "No exercises logged yet" : "No match", systemImage: "chart.xyaxis.line")
                    .listRowBackground(Color.clear)
            }
            ForEach(list) { e in
                NavigationLink(value: TodayRouter.Route.progress(e.id)) {
                    HStack {
                        Text(e.name).foregroundStyle(.primary)
                        Spacer(minLength: 8)
                        if let value = e.value {
                            Text(value).foregroundStyle(.secondary).monospacedDigit()
                        }
                    }
                }
            }
        }
        .navigationTitle("Exercise progress")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("Search…"))
    }
}

/// Stats.jsx's Exercise progress card as a screen: the top-set, estimated-1RM and effort curves,
/// the best, the best set ever and the last five sessions.
struct ExerciseProgressView: View {
    let exerciseId: String
    @Environment(GymStore.self) private var store
    @AppStorage("gf.progressMetric") private var metric = "top"

    var body: some View {
        if let p = store.exerciseProgress(exerciseId), p.sessions > 0 {
            content(p)
        } else {
            ContentUnavailableView("No sessions logged yet", systemImage: "chart.xyaxis.line",
                                   description: Text("Finish your first workout to see progress curves here."))
                .navigationTitle(store.exerciseProgress(exerciseId)?.name ?? "")
        }
    }

    private func content(_ p: ExerciseProgress) -> some View {
        let options = p.metrics.compactMap { o in o.value.string.map { ($0, o.label) } }
        let on = options.contains { $0.0 == metric } ? metric : "top"
        return List {
            Section {
                if options.count > 1 {
                    Picker("Curve", selection: $metric) {
                        ForEach(options, id: \.0) { Text($0.1).tag($0.0) }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("progress.metric")
                }
                switch on {
                case "e1rm": ProgressChart(points: p.e1rm, unit: store.prefs()?.unit ?? "kg")
                case "effort": ProgressChart(points: p.effort, unit: p.scale, color: .yellow, inverted: p.invertEffort)
                default: ProgressChart(points: p.top, unit: p.unit)
                }
                VStack(alignment: .leading, spacing: 4) {
                    let caption = on == "e1rm" ? p.captions.e1rm : on == "effort" ? p.captions.effort : p.captions.top
                    if on == "effort" {
                        Text(caption)
                    } else {
                        Text("\(caption) · \(p.bestLabel) \(Text(on == "e1rm" ? (p.best.e1rm ?? "—") : p.best.top).bold().foregroundStyle(Color.accentColor))")
                    }
                    if on == "e1rm", let note = p.e1rmNote { Text(note) }
                    if on == "top", let note = p.effortNote { Text(note) }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
            if let best = p.bestSet {
                Section("Best set") {
                    HStack {
                        Label(best.text, systemImage: "trophy.fill")
                            .labelStyle(.titleAndIcon)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text(best.date).foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            Section("Recent workouts") {
                ForEach(Array(p.recent.enumerated()), id: \.offset) { _, s in
                    HStack(alignment: .firstTextBaseline) {
                        Text(s.date).foregroundStyle(.secondary)
                        Spacer(minLength: 12)
                        Text(s.sets).multilineTextAlignment(.trailing)
                    }
                    .font(.subheadline)
                }
            }
            if store.oneRM(exerciseId)?.available == true {
                Section {
                    NavigationLink { OneRMCalculatorView(exerciseId: exerciseId) } label: {
                        Label("1RM calculator", systemImage: "function")
                    }
                }
            }
        }
        .navigationTitle(p.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}
