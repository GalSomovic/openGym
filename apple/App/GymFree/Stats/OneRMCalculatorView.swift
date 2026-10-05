import OpenGymCore
import SwiftUI

/// sheets.jsx OneRM as list sections: the estimate your log already implies, and a calculator for
/// a set you have not done (Epley, 1–12 reps), read back as the load for 1–12 reps.
struct OneRMSections: View {
    let exerciseId: String
    /// Shows the 1–12 rep table (the full calculator) or just the estimate (exercise detail).
    var showTable = true
    @Environment(GymStore.self) private var store
    @State private var weight: Double?
    @State private var reps: Double?

    var body: some View {
        if let calc = store.oneRM(exerciseId, weight: weight, reps: reps), calc.available {
            Section {
                if let log = calc.fromLog {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(log.label) \(Text(log.value).bold().foregroundStyle(Color.accentColor))")
                        Text(log.line).font(.footnote).foregroundStyle(.secondary)
                    }
                }
                NumberStepper(label: LocalizedStringKey(calc.weightLabel), value: binding(\.w, $weight, calc),
                              step: calc.step, decimals: 2, range: 0...2000)
                NumberStepper(label: LocalizedStringKey(calc.repsLabel), value: binding(\.r, $reps, calc), step: 1, range: 1...50)
                HStack {
                    Text(calc.estimateLabel).foregroundStyle(.secondary)
                    Spacer()
                    Text(calc.estimateText).font(.title3.weight(.bold)).foregroundStyle(Color.accentColor).monospacedDigit()
                        .accessibilityIdentifier("onerm.estimate")
                }
                .accessibilityElement(children: .combine)
            } header: {
                Text(calc.title)
            } footer: {
                Text(calc.note)
            }
            if showTable, !calc.table.isEmpty {
                Section("Rep maxes") {
                    ForEach(calc.table) { row in
                        HStack {
                            Text("\(row.reps) × \(Text(row.text).fontWeight(.semibold))").monospacedDigit()
                            Spacer()
                            Text("\(row.pct)%").foregroundStyle(.secondary).monospacedDigit()
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }

    /// Opens on the engine's starting set (the best logged, or the working weight × 5) until edited.
    private func binding(_ key: KeyPath<OneRMCalc, Double>, _ state: Binding<Double?>, _ calc: OneRMCalc) -> Binding<Double> {
        Binding(get: { state.wrappedValue ?? calc[keyPath: key] }, set: { state.wrappedValue = $0 })
    }
}

/// The calculator on a screen of its own, from exercise progress.
struct OneRMCalculatorView: View {
    let exerciseId: String
    @Environment(ExerciseCatalog.self) private var catalog

    var body: some View {
        List { OneRMSections(exerciseId: exerciseId) }
            .navigationTitle(catalog.name(exerciseId))
            .navigationBarTitleDisplayMode(.inline)
    }
}
