import OpenGymCore
import SwiftUI

/// The plates you own (openGym's PlateInventorySheet): every set's plate line loads from this list,
/// so a home gym with one pair of 20s is never told to use two.
struct PlateInventoryView: View {
    @Environment(GymStore.self) private var store

    private struct Plate: Decodable, Hashable { var w: Double; var n: Int }
    private struct Inventory: Decodable { var unit: String; var own: Bool; var plates: [Plate] }

    var body: some View {
        let inv = store.query("platesActions", "inventory", as: Inventory.self)
        List {
            Section {
                ForEach(inv?.plates ?? [], id: \.self) { p in
                    Stepper(value: Binding(get: { p.n }, set: { store.perform("platesActions", "setPairs", [p.w, $0], as: JSONValue.self) }), in: 0...20) {
                        LabeledContent("\(Fmt.num(p.w)) \(inv?.unit ?? "kg")", value: String(localized: "\(p.n) pairs"))
                    }
                }
            } footer: {
                Text(inv?.own == true ? "Your own list for \(inv?.unit ?? "kg")." : "The standard set, plenty of each. Change any count to make it yours.")
            }
            if inv?.own == true {
                Section { Button("Back to the standard set") { store.perform("platesActions", "resetPlates", as: JSONValue.self) } }
            }
        }
        .navigationTitle("Plates")
    }
}

/// How one exercise loads (openGym's BarWeightEditor): per side, single stack or off; the bar's
/// own weight, or "no bar". Applies to the exercise everywhere.
struct PlateLoadingSection: View {
    let exerciseId: String
    @Environment(GymStore.self) private var store

    private struct Loading: Decodable { var kind: String; var bar: Bool; var noBar: Bool; var explicit: Bool; var base: Double; var defaultBar: Double; var unit: String }

    var body: some View {
        if let l = store.query("platesActions", "loading", [exerciseId], as: Loading?.self) ?? nil {
            Section {
                Picker("Plates", selection: Binding(get: { l.kind }, set: { store.perform("platesActions", "setKind", [exerciseId, $0], as: JSONValue.self) })) {
                    Text("Per side").tag("pairs")
                    Text("Single stack").tag("single")
                    Text("Off").tag("none")
                }
                .pickerStyle(.segmented)
                if l.kind != "none" {
                    if l.bar {
                        Toggle("No bar", isOn: Binding(get: { l.noBar }, set: { store.perform("platesActions", "setNoBar", [exerciseId, $0], as: JSONValue.self) }))
                    }
                    if !l.noBar {
                        Stepper(value: Binding(get: { l.base }, set: { store.perform("platesActions", "setBase", [exerciseId, $0], as: JSONValue.self) }), in: 0...100, step: 2.5) {
                            LabeledContent(l.bar ? "Bar" : "Base weight", value: "\(Fmt.num(l.base)) \(l.unit)")
                        }
                    }
                }
            } header: { Text("Plate loading") } footer: {
                Text(l.kind == "pairs" ? "Plates split over both sides of a bar."
                     : l.kind == "single" ? "One stack: a belt, a landmine, a plate-loaded machine, a sled."
                     : "No plate line under the sets.")
            }
        }
    }
}

/// The plate-loading editor on its own, from the workout's exercise menu.
struct PlateLoadingSheet: View {
    let exerciseId: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form { PlateLoadingSection(exerciseId: exerciseId) }
                .navigationTitle("Plate loading")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
        .presentationDetents([.medium])
    }
}
