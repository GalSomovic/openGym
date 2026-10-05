import OpenGymCore
import SwiftUI

/// StructuralBalance.jsx: your lifts against a published ratio table (Poliquin, Thibaudeau,
/// ATG), to find the one holding the rest back. Any lift can be pointed at another exercise.
struct StructuralBalanceView: View {
    @Environment(GymStore.self) private var store
    @State private var changing: BalanceRow?
    @State private var weighIn = false

    var body: some View {
        if let b = store.structuralBalance() {
            List {
                Section {
                    Picker("Table", selection: Binding(get: { b.template }, set: { store.setBalanceTemplate($0) })) {
                        ForEach(b.templates) { Text($0.label).tag($0.id) }
                    }
                    .pickerStyle(.menu)
                } footer: {
                    Text(b.subtitle)
                }
                Section {
                    ForEach(b.rows) { row($0) }
                }
            }
            .navigationTitle(b.title)
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $changing) { row in
                ExercisePickerSheet(title: "Change exercise", onQuick: { id in
                    store.setBalanceExercise(row.role, id)
                    changing = nil
                }, configure: { id in
                    List {
                        Button("Use for \(row.label)", systemImage: "checkmark") {
                            store.setBalanceExercise(row.role, id)
                            changing = nil
                        }
                    }
                })
            }
            .sheet(isPresented: $weighIn) { WeighInSheet(mode: .log) }
        }
    }

    private func row(_ r: BalanceRow) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(r.label)
                    if let name = r.exercise {
                        Text(r.custom ? "\(name) · \(String(localized: "Custom"))" : name)
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    if r.needsBodyweight {
                        Text("Log your body weight to score this lift.").font(.footnote).foregroundStyle(.secondary)
                    }
                    if r.needsAnchor {
                        Text("Log the anchor lift to score this one.").font(.footnote).foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(r.statusLabel).foregroundStyle(Self.color(r.status)).fontWeight(.semibold)
                    Text(r.value).font(.footnote).foregroundStyle(.secondary).monospacedDigit()
                }
            }
            HStack(spacing: 8) {
                if r.needsBodyweight {
                    Button("Log body weight", systemImage: "plus") { weighIn = true }
                }
                Button("Change exercise", systemImage: "pencil") { changing = r }
                if r.custom {
                    Button("Use default exercise") { store.setBalanceExercise(r.role, nil) }
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier("balance.\(r.role)")
    }

    static func color(_ status: String) -> Color {
        switch status {
        case "balanced": .green
        case "borderline": .yellow
        case "weak": .red
        default: .secondary
        }
    }
}
