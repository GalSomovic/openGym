import OpenGymCore
import SwiftUI

/// sheets.jsx WeightInput: fine steps of 0.1, quick steps of 0.5 and 1, a slider, or typed.
struct WeightInput: View {
    @Binding var value: Double
    let unit: String
    /// The ceiling in this unit: 300 kg or 660 lb.
    let max: Double
    @FocusState private var focused: Bool
    @State private var text = ""

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 18) {
                round("minus", by: -0.1).accessibilityLabel(Text("Decrease by \(Fmt.num(0.1))"))
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    TextField("", text: $text)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 44, weight: .bold).monospacedDigit())
                        .fixedSize()
                        .focused($focused)
                        .onChange(of: text) { _, new in
                            guard focused, let v = Double(new.replacingOccurrences(of: ",", with: ".")) else { return }
                            value = v
                        }
                        .accessibilityLabel(Text("Weight (\(unit))"))
                        .accessibilityIdentifier("weight.field")
                    Text(unit).font(.title3).foregroundStyle(.secondary)
                }
                round("plus", by: 0.1).accessibilityLabel(Text("Increase by \(Fmt.num(0.1))"))
            }
            HStack(spacing: 8) {
                ForEach([-1, -0.5, 0.5, 1], id: \.self) { d in
                    Button(d > 0 ? "+\(Fmt.num(d))" : "−\(Fmt.num(-d))") { set(value + d) }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .font(.subheadline.monospacedDigit())
                }
            }
            Slider(value: Binding(get: { Swift.min(max, Swift.max(1, value)) }, set: { set($0) }), in: 1...max, step: 0.5)
                .accessibilityLabel(Text("Weight"))
        }
        .onAppear { text = Fmt.num(value) }
        .onChange(of: value) { _, v in if !focused { text = Fmt.num(v) } }
        .onChange(of: focused) { _, f in if !f { text = Fmt.num(value) } }
    }

    private func round(_ symbol: String, by step: Double) -> some View {
        Button { set(value + step) } label: { Image(systemName: symbol).font(.title3.weight(.semibold)).frame(width: 28, height: 28) }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
    }

    private func set(_ v: Double) {
        value = Swift.max(1, Swift.min(max, (v * 10).rounded() / 10))
    }
}

/// sheets.jsx BwSheet: logging today's weight, or the quick check-in before a workout (when the
/// weigh-in is on), which can always be skipped.
struct WeighInSheet: View {
    enum Mode: Equatable {
        case log
        case beforeWorkout([String])
    }

    let mode: Mode
    @Environment(GymStore.self) private var store
    @Environment(TodayRouter.self) private var router
    @Environment(WorkoutSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var value: Double = 70
    @State private var loaded = false

    private var routineIds: [String]? { if case .beforeWorkout(let ids) = mode { ids } else { nil } }

    var body: some View {
        let card = store.weightCard()
        NavigationStack {
            Form {
                Section {
                    WeightInput(value: $value, unit: card?.unit ?? "kg", max: card?.max ?? 300)
                        .padding(.vertical, 8)
                } footer: {
                    if routineIds != nil {
                        Text("Slide or tap to set your weight — tracked before every workout so your curve stays honest.")
                    } else if let today = card?.today {
                        Text(today)
                    }
                }
                if routineIds != nil {
                    Section {
                        Button { begin(saving: true) } label: {
                            Text("Save & start workout").frame(maxWidth: .infinity).fontWeight(.semibold)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        Button { begin(saving: false) } label: {
                            Text("Start without weighing in").frame(maxWidth: .infinity)
                        }
                        .listRowBackground(Color.clear)
                    }
                } else if let recent = store.weighIns()?.weeks.flatMap(\.entries).prefix(3), !recent.isEmpty {
                    // The ones just typed: taking back a typo is one tap (no confirmation).
                    Section("Recent weigh-ins") {
                        ForEach(Array(recent), id: \.d) { b in
                            HStack {
                                Text(b.date).foregroundStyle(.secondary)
                                Spacer()
                                Text(b.text).fontWeight(.semibold)
                                Button { store.deleteWeighIn(b.d) } label: { Image(systemName: "trash") }
                                    .buttonStyle(.borderless)
                                    .foregroundStyle(.red)
                                    .accessibilityLabel(Text("Delete weigh-in"))
                            }
                        }
                    }
                }
            }
            .navigationTitle(routineIds != nil ? "Quick check-in" : "Log body weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                if routineIds == nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            if store.logWeight(value) != nil { session.toast = String(localized: "Weight saved") }
                            dismiss()
                        }
                        .fontWeight(.semibold)
                    }
                }
            }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                if let w = card?.last?.w { value = w }
            }
        }
        .presentationDetents([.large])
        // Locked, like openGym's: a stray swipe does not walk back a tap on Start.
        .interactiveDismissDisabled(routineIds != nil)
    }

    private func begin(saving: Bool) {
        guard let ids = routineIds else { return }
        let bw = saving ? store.logWeight(value) : nil
        router.sheet = nil
        store.beginWorkout(routineIds: ids, bodyWeight: bw, freestyleName: String(localized: "Freestyle"))
    }
}

/// sheets.jsx GoalSheet: the target weight, drawn as a line through the charts.
struct WeightGoalSheet: View {
    @Environment(GymStore.self) private var store
    @Environment(WorkoutSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var value: Double = 70
    @State private var loaded = false

    var body: some View {
        let card = store.weightCard()
        NavigationStack {
            Form {
                Section {
                    WeightInput(value: $value, unit: card?.unit ?? "kg", max: card?.max ?? 300).padding(.vertical, 8)
                } footer: {
                    Text("Your goal is drawn as a line through the weight charts, and gains/losses are colored by whether they move toward it.")
                }
                if card?.goal != nil {
                    Section {
                        Button("Remove goal", role: .destructive) {
                            session.toast = store.setWeightGoal(nil)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Target weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save goal") {
                        session.toast = store.setWeightGoal(value)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                if let w = card?.goal ?? card?.last?.w { value = w }
            }
        }
        .presentationDetents([.large])
    }
}
