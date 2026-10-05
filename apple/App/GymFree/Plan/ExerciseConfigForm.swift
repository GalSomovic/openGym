import OpenGymCore
import SwiftUI

/// openGym's exercise settings sheet (sheets.jsx ExConfig): sets, reps, weight, warm-ups, rest,
/// bodyweight and per-side, intensifiers, progression and a note. Which fields show, and what
/// Save stores, both come from the engine (plan.js configInfo / configToSave).
struct ExerciseConfigForm: View {
    let exerciseId: String
    let routineId: String?
    let saveLabel: LocalizedStringKey
    var extraActions: AnyView? = nil
    let onSave: (ExerciseConfig) -> Void

    @Environment(GymStore.self) private var store
    @Environment(ExerciseCatalog.self) private var catalog
    @State private var draft: ExerciseConfig
    @State private var info: ConfigInfo?

    init(exerciseId: String, routineId: String?, start: ExerciseConfig, saveLabel: LocalizedStringKey,
         extraActions: AnyView? = nil, onSave: @escaping (ExerciseConfig) -> Void) {
        self.exerciseId = exerciseId
        self.routineId = routineId
        self.saveLabel = saveLabel
        self.extraActions = extraActions
        self.onSave = onSave
        _draft = State(initialValue: start)
    }

    var body: some View {
        Form {
            Section {
                HStack(spacing: 14) {
                    ExerciseAnimation(exerciseId: exerciseId)
                        .frame(width: 110, height: 110)
                        .clipShape(.rect(cornerRadius: 14))
                    VStack(alignment: .leading, spacing: 4) {
                        Text(catalog.name(exerciseId)).font(.headline)
                        if let e = catalog[exerciseId] {
                            Text(catalog.subtitle(e)).font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            if let info { fields(info) }
            Section {
                TextField("Note (optional): loading cues, anything worth remembering", text: text("note"), axis: .vertical)
                    .lineLimit(2...5)
            }
            Section {
                Button {
                    if let cfg = store.configToSave(exerciseId, draft, routine: routineId) { onSave(cfg) }
                } label: {
                    Text(saveLabel).frame(maxWidth: .infinity).fontWeight(.semibold)
                }
                .buttonStyle(.borderedProminent)
                .disabled(info?.stepValid == false)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            if let extraActions { extraActions }
        }
        .onAppear { refresh() }
        .onChange(of: draft) { refresh() }
    }

    private func refresh() { info = store.configInfo(exerciseId, draft, routine: routineId) }

    @ViewBuilder
    private func fields(_ info: ConfigInfo) -> some View {
        let restPause = draft["intensifier"]?["type"]?.string == "restpause"
        let weightUnit = info.unit
        Section {
            if !info.cardio {
                Picker("Type", selection: Binding(
                    get: { info.mode },
                    set: { draft = store.configWithMode(exerciseId, draft, $0, routine: routineId) })) {
                    Text("Reps").tag("reps")
                    Text("Time").tag("time")
                }
                .pickerStyle(.segmented)
            }
            if info.cardio {
                NumberStepper(label: "Intervals", value: number("sets", 1), range: 1...50)
                NumberStepper(label: "Minutes", value: number("min", 20), range: 1...600)
                NumberStepper(label: info.speedUnit == "mph" ? "Speed (mph)" : "Speed (km/h)",
                              value: speed(info.speedUnit), step: 0.5, decimals: 1, range: 0...60)
            } else if info.mode == "time" {
                NumberStepper(label: "Sets", value: number("sets", 3), range: 1...50)
                NumberStepper(label: "Seconds", value: number("sec", 45), step: 5, range: 1...3600)
                if !info.bw {
                    NumberStepper(label: "Weight", value: number("weight", 0), step: 2.5, decimals: 2, unit: weightUnit)
                }
            } else {
                if !restPause { NumberStepper(label: "Sets", value: number("sets", 3), range: 1...50) }
                if !info.double {
                    NumberStepper(label: "Reps", value: number("reps", 10), step: info.perSide ? 2 : 1, range: 1...1000)
                }
                if !info.bw {
                    NumberStepper(label: "Weight", value: number("weight", 0), step: 2.5, decimals: 2, unit: weightUnit)
                }
            }
        } footer: {
            if restPause {
                Text("Rest-pause always trains as one warm-up set at this rep count, then one rest-pause work set. “Sets” is not used.")
            } else if info.mode == "time" && !info.bw {
                Text("A timer runs while you hold the set. Leave the weight at 0 for bodyweight holds.")
            }
        }
        if !info.cardio && !restPause {
            Section {
                NumberStepper(label: "Warm-up sets", value: number("warmupSets", 0), range: 0...Double(info.maxWarmups))
            } footer: {
                Text((draft["warmupSets"]?.number ?? 0) > 0
                     ? "Added before your work sets and left out of volume, records and progression."
                     : "Ramp-up sets added before the work sets, so you don’t have to add them by hand each session.")
            }
        }
        Section {
            NumberStepper(label: "Rest (s)", value: number("restSec", 0), step: 15, range: 0...1800)
        } footer: {
            Text("Rest after each set of this exercise. Leave at 0 to use your default rest timer.")
        }
        if !info.cardio {
            Section {
                Toggle(isOn: Binding(get: { info.bw }, set: { on in
                    draft["bodyweight"] = .bool(on)
                    if on { draft["weight"] = .number(0) }
                })) {
                    Label("Bodyweight", systemImage: "figure.strengthtraining.functional")
                }
                if info.mode == "reps" {
                    Toggle(isOn: Binding(get: { info.perSide }, set: {
                        draft = store.configWithPerSide(exerciseId, draft, $0, routine: routineId)
                    })) {
                        Label("Reps per side", systemImage: "arrow.left.and.right")
                    }
                }
                if info.bw {
                    NumberStepper(label: "Added weight", value: number("weight", 0), step: 2.5, decimals: 2, unit: weightUnit)
                }
                if info.mode == "reps" && info.bw && (draft["weight"]?.number ?? 0) <= 0 {
                    NumberStepper(label: "Top of the range", value: number("repsMax", 0), range: 0...1000)
                }
            } footer: {
                if info.mode == "reps" && info.bw && (draft["weight"]?.number ?? 0) <= 0 {
                    let top = Int(draft["repsMax"]?.number ?? 0)
                    Text(top > 0
                         ? "Reps climb to \(top), then a set is added and the reps start over. At \(info.maxBwSets) sets it asks you to add weight instead."
                         : "Reps climb by one whenever every set was clean. Set a ceiling to add sets instead of reps forever.")
                } else if info.perSide {
                    Text("You still log the total: \(Int(draft["reps"]?.number ?? 0)) is \(Int((draft["reps"]?.number ?? 0) / 2)) per side.")
                }
            }
        }
        if info.mode == "reps" { intensifier(info) }
        if !info.policies.isEmpty { progression(info) }
        if info.mode == "reps" { PlateLoadingSection(exerciseId: exerciseId) }
    }

    @ViewBuilder
    private func intensifier(_ info: ConfigInfo) -> some View {
        let type = draft["intensifier"]?["type"]?.string ?? ""
        Section {
            Picker("Intensifier", selection: Binding(get: { type }, set: {
                draft = store.configWithIntensifier(draft, $0)
            })) {
                Text("None").tag("")
                Text("Drop-set").tag("dropset")
                Text("Rest-pause").tag("restpause")
            }
            if type == "dropset" {
                NumberStepper(label: "Drops", value: intensifierNumber("count"), range: 1...10)
                NumberStepper(label: "Weight drop (%)", value: intensifierNumber("pct"), step: 5, range: 5...90)
            } else if type == "restpause" {
                NumberStepper(label: "Rest-pause reps", value: intensifierNumber("totalReps"), range: 1...100)
                NumberStepper(label: "Rest (s)", value: intensifierNumber("restSec"), step: 5, range: 5...120)
            }
        } header: {
            Text("Drop-set / rest-pause")
        } footer: {
            if type == "dropset" {
                Text("Every set becomes a drop-set: after the main set, \(Int(draft["intensifier"]?["count"]?.number ?? 1)) drop(s) with no rest, each about \(Int(draft["intensifier"]?["pct"]?.number ?? 20))% lighter.")
            } else if type == "restpause" {
                Text("Every set becomes rest-pause: \(Int(draft["reps"]?.number ?? 0)) reps to start, then \(Int(draft["intensifier"]?["totalReps"]?.number ?? 0)) more split into short bursts, \(Int(draft["intensifier"]?["restSec"]?.number ?? 15))s rest before each.")
            }
        }
    }

    @ViewBuilder
    private func progression(_ info: ConfigInfo) -> some View {
        let rule = draft["prog"]?.string ?? ""
        Section {
            Picker("Rule", selection: Binding(get: { rule }, set: {
                draft = store.configWithRule(exerciseId, draft, $0, routine: routineId)
            })) {
                Text("Follow the routine (\(info.policyNames[info.inheritedPolicy] ?? info.inheritedPolicy))").tag("")
                ForEach(info.policies, id: \.self) { p in Text(info.policyNames[p] ?? p).tag(p) }
            }
            if info.policy != "off" {
                NumberStepper(label: info.mode == "time" ? "Step (seconds)" : "Step (\(info.unit))",
                              value: Binding(get: { draft["inc"]?.number ?? info.step }, set: { draft["inc"] = .number($0) }),
                              step: info.mode == "time" ? 5 : 1.25, decimals: info.mode == "time" ? 0 : 2)
                if info.double {
                    let stride: Double = info.perSide ? 2 : 1
                    NumberStepper(label: "Reps from", value: Binding(
                        get: { draft["repsMin"]?.number ?? info.range?.repsMin ?? 8 }, set: { draft["repsMin"] = .number($0) }),
                                  step: stride, range: 1...1000)
                    NumberStepper(label: "Reps up to", value: Binding(
                        get: { draft["reps"]?.number ?? info.range?.reps ?? 12 }, set: { draft["reps"] = .number($0) }),
                                  step: stride, range: 1...1000)
                }
                if info.epleyEligible {
                    NumberStepper(label: "Deload 1RM (%)", value: Binding(
                        get: { ((draft["deloadFactor"]?.number ?? 0.9) * 100).rounded() },
                        set: { draft["deloadFactor"] = .number($0 / 100) }), step: 5, range: 50...95)
                }
            }
        } header: {
            Text("Progression")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                if let desc = info.policyDesc { Text(desc) }
                if !info.stepValid {
                    Text("Enter a positive step to use this progression rule.").foregroundStyle(.red)
                }
            }
        }
    }

    /* bindings into the draft */

    private func number(_ key: String, _ fallback: Double) -> Binding<Double> {
        Binding(get: { draft[key]?.number ?? fallback }, set: { draft[key] = .number($0) })
    }

    private func text(_ key: String) -> Binding<String> {
        Binding(get: { draft[key]?.string ?? "" }, set: { draft[key] = .string($0) })
    }

    private func intensifierNumber(_ key: String) -> Binding<Double> {
        Binding(get: { draft["intensifier"]?[key]?.number ?? 0 }, set: { v in
            guard case .object(var o)? = draft["intensifier"] else { return }
            o[key] = .number(v)
            draft["intensifier"] = .object(o)
        })
    }

    /// Typed in the profile's speed unit, kept in km/h (openGym lib/speed.js).
    private func speed(_ unit: String) -> Binding<Double> {
        let factor = unit == "mph" ? 1.609344 : 1
        return Binding(get: { ((draft["speed"]?.number ?? 8) / factor * 10).rounded() / 10 },
                       set: { draft["speed"] = .number($0 * factor) })
    }
}
