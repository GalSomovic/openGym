import OpenGymCore
import SwiftUI

/// Create or edit your own exercise (openGym's CustomExForm, apple/core/custom.js): a name, a
/// body part and equipment, the muscles it works, and notes. It then behaves like any other.
struct CustomExerciseForm: View {
    var editing: String?
    var onSaved: (String) -> Void = { _ in }
    @Environment(GymStore.self) private var store
    @Environment(ExerciseCatalog.self) private var catalog
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var bodyPart = ""
    @State private var equipment = ""
    @State private var notes = ""
    @State private var primaries: [String] = []
    @State private var secondaries: [String] = []
    @State private var error: String?
    @State private var confirmDelete = false
    @State private var loaded = false

    private struct Options: Decodable { struct M: Decodable, Hashable { var id: String; var name: String }
        var bodyParts: [String]; var equipment: [String]; var muscles: [M] }
    private struct Stored: Decodable { var n: String; var bp: String; var eq: String?; var desc: String?; var primaries: [String]?; var secondaries: [String]? }
    private struct Result: Decodable { var id: String?; var error: String?; var name: String? }

    var body: some View {
        let o = store.query("custom", "options", as: Options.self) ?? Options(bodyParts: [], equipment: [], muscles: [])
        NavigationStack {
            Form {
                Section {
                    TextField("Exercise name", text: $name).accessibilityIdentifier("custom.name")
                    Picker("Body part", selection: $bodyPart) {
                        Text("Choose").tag("")
                        ForEach(o.bodyParts, id: \.self) { Text($0.capitalized).tag($0) }
                    }
                    Picker("Equipment", selection: $equipment) {
                        Text("Choose").tag("")
                        ForEach(o.equipment, id: \.self) { Text($0.capitalized).tag($0) }
                    }
                } footer: { Text("Name it and pick a body part; it behaves like any other exercise.") }
                if bodyPart != "cardio" {
                    Section("Main muscles") { muscleChips(o.muscles, selection: $primaries, other: $secondaries) }
                    Section("Also works") { muscleChips(o.muscles, selection: $secondaries, other: $primaries) }
                }
                Section("How to do it (optional)") {
                    TextField("Steps, cues, setup…", text: $notes, axis: .vertical).lineLimit(3...8)
                }
                if let error { Section { Text(error).foregroundStyle(.red) } }
                if editing != nil {
                    Section {
                        Button("Delete exercise", role: .destructive) { confirmDelete = true }
                    } footer: { Text("It will be removed from your routines. Logged workouts keep their sets.") }
                }
            }
            .navigationTitle(editing == nil ? "New exercise" : "Edit exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Save") { save() }.accessibilityIdentifier("custom.save") }
            }
            .confirmationDialog("Delete “\(name)”?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let id = editing { store.perform("custom", "remove", [id], as: JSONValue.self) }
                    catalog.reload()
                    dismiss()
                }
            }
            .onAppear(perform: load)
        }
    }

    private func muscleChips(_ muscles: [Options.M], selection: Binding<[String]>, other: Binding<[String]>) -> some View {
        FlowLayout(spacing: 6) {
            ForEach(muscles, id: \.self) { m in
                let on = selection.wrappedValue.contains(m.id)
                Button {
                    if on { selection.wrappedValue.removeAll { $0 == m.id } }
                    else { selection.wrappedValue.append(m.id); other.wrappedValue.removeAll { $0 == m.id } }
                } label: {
                    Text(m.name).font(.subheadline)
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(on ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary.opacity(0.6)), in: .capsule)
                        .foregroundStyle(on ? .white : .primary)
                }
                .buttonStyle(.borderless)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        guard let id = editing, let s = store.query("custom", "get", [id], as: Stored?.self) ?? nil else { return }
        name = s.n; bodyPart = s.bp; equipment = s.eq ?? ""; notes = s.desc ?? ""
        primaries = s.primaries ?? []; secondaries = s.secondaries ?? []
    }

    private func save() {
        var spec: [String: Any] = ["n": name, "bp": bodyPart, "eq": equipment, "desc": notes, "primaries": primaries, "secondaries": secondaries]
        if let editing { spec["id"] = editing }
        guard let r = store.perform("custom", "save", [spec], as: Result.self) else { return }
        switch r.error {
        case "name": error = String(localized: "Give it a name.")
        case "bodyPart": error = String(localized: "Pick a body part.")
        case "equipment": error = String(localized: "Pick equipment.")
        case "duplicate": error = String(localized: "“\(r.name ?? name)” already exists.")
        default:
            catalog.reload()
            if let id = r.id { onSaved(id) }
            dismiss()
        }
    }
}
