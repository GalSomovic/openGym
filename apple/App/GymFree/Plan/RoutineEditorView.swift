import OpenGymCore
import SwiftUI

/// openGym's routine editor: name and icon, progression rule, deload switch, the exercises
/// (settings, supersets, order, replace), and what the session works.
struct RoutineEditorView: View {
    let routineId: String
    @Environment(GymStore.self) private var store
    @Environment(ExerciseCatalog.self) private var catalog
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var editing: Slot?
    @State private var replacing: Int?
    @State private var adding = false
    @State private var confirmDelete = false
    @State private var reordering = false

    private struct Slot: Identifiable { let index: Int; var id: Int { index } }

    private var routine: Routine? { store.routines.first { $0.id == routineId } }
    private var policyNames: [String: String] { (try? Engine.shared.value("progression", "POLICY_NAME", as: [String: String].self)) ?? [:] }
    private var policyDescs: [String: String] { (try? Engine.shared.value("progression", "POLICY_DESC", as: [String: String].self)) ?? [:] }
    private static let routinePolicies = ["off", "linear", "greyskull", "double"]

    var body: some View {
        if let routine {
            content(routine)
        } else {
            ContentUnavailableView("Routine deleted", systemImage: "trash")
        }
    }

    @ViewBuilder
    private func content(_ r: Routine) -> some View {
        let lines = store.routineLines(routineId)
        let missing = Set(store.missingEquipment(routineId))
        List {
            Section {
                HStack(spacing: 12) {
                    Menu {
                        ForEach(Array(Glyphs.groups.enumerated()), id: \.offset) { _, group in
                            Section {
                                ForEach(group.items, id: \.self) { key in
                                    Button { store.setRoutineEmoji(routineId, key) } label: {
                                        Label(key, systemImage: Glyphs.symbol(key))
                                            .labelStyle(.iconOnly)
                                    }
                                }
                            } header: {
                                Text(group.key)
                            }
                        }
                    } label: {
                        RoutineIcon(emoji: r.emoji, size: 44)
                    }
                    .accessibilityLabel(Text("Pick an icon"))
                    TextField("Routine name", text: $name)
                        .font(.title3.weight(.semibold))
                        .submitLabel(.done)
                        .onChange(of: name) { _, new in
                            store.renameRoutine(routineId, new, fallback: String(localized: "Routine"))
                        }
                }
            }
            Section {
                Picker(selection: Binding(get: { r.prog ?? "linear" }, set: { store.setRoutineProgression(routineId, $0) })) {
                    ForEach(Self.routinePolicies, id: \.self) { p in Text(policyNames[p] ?? p).tag(p) }
                } label: {
                    Label("Progression", systemImage: "chart.line.uptrend.xyaxis")
                }
                Toggle(isOn: Binding(get: { r.excludeFromProgression == true }, set: { store.setRoutineDeload(routineId, $0) })) {
                    Label("Deload routine", systemImage: "pause.circle")
                }
            } footer: {
                if r.excludeFromProgression == true {
                    Text("A deload routine opens at the numbers set here, so progression doesn’t apply to it. Its workouts still show in history and statistics.")
                } else {
                    Text("\(policyDescs[r.prog ?? "linear"] ?? "") Applies to every exercise in this routine that doesn’t set its own rule.")
                }
            }
            if !missing.isEmpty {
                Section {
                    Label("\(missing.count) of \(r.ex.count) exercises need equipment you don’t have. Replace them, or change your equipment in Settings.",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.orange)
                }
            }
            Section {
                ForEach(Array(r.ex.enumerated()), id: \.offset) { i, e in
                    exerciseRow(r, i, e, line: i < lines.count ? lines[i] : "", missing: missing.contains(i))
                }
                .onMove { from, to in
                    guard let source = from.first else { return }
                    store.reorderRoutineExercise(routineId, from: source, toSlot: slot(r, source: source, destination: to))
                }
                Button { adding = true } label: {
                    Label("Add exercise", systemImage: "plus.circle.fill").fontWeight(.semibold)
                }
            } header: {
                HStack {
                    Text("Exercises")
                    Spacer()
                    if r.ex.count > 1 {
                        Button(reordering ? "Done" : "Reorder") { withAnimation { reordering.toggle() } }
                            .font(.subheadline.weight(reordering ? .semibold : .regular))
                            .textCase(nil)
                    }
                }
            } footer: {
                if reordering {
                    Text("Drag the handles to change the order. Supersets move together.")
                } else if r.ex.count > 1 {
                    Text("Tap an exercise to change its sets and reps. Swipe right to superset it with the one above, left to remove it.")
                }
            }
            if !r.ex.isEmpty, let muscles = store.routineMuscles(routineId), !muscles.worked.isEmpty {
                // RoutineEdit.jsx: the routine as planned on a body map, so a gap shows while you build it.
                Section("What this session hits") {
                    BodyMapView(levels: muscles.levels)
                        .frame(maxHeight: 220)
                        .padding(.vertical, 4)
                    FlowTags(tags: muscles.worked.prefix(6).map { catalog.muscleName($0) })
                }
            }
            Section {
                Button("Copy routine", systemImage: "doc.on.doc") {
                    _ = store.copyRoutine(routineId, suffix: String(localized: "Copy"))
                }
                Button("Delete routine", systemImage: "trash", role: .destructive) { confirmDelete = true }
            }
        }
        .navigationTitle(r.name)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, .constant(reordering ? .active : .inactive))
        .safeAreaInset(edge: .bottom) {
            Text("Changes save automatically")
                .font(.caption).foregroundStyle(.secondary)
                .padding(.bottom, 4)
        }
        .onAppear {
            name = r.name
            if let i = DebugLaunch.config, editing == nil, i < r.ex.count { editing = Slot(index: i) }
        }
        .sheet(item: $editing) { slot in
            NavigationStack {
                let configs = store.routineConfigs(routineId)
                let exId = r.ex[slot.index].id
                ExerciseConfigForm(
                    exerciseId: exId, routineId: routineId,
                    start: store.configStart(exId, existing: slot.index < configs.count ? configs[slot.index] : nil, routine: routineId),
                    saveLabel: "Save",
                    extraActions: AnyView(Section {
                        Button("Replace exercise", systemImage: "arrow.triangle.2.circlepath") {
                            editing = nil
                            replacing = slot.index
                        }
                        Button("Remove from routine", systemImage: "trash", role: .destructive) {
                            editing = nil
                            store.removeRoutineExercise(routineId, slot.index)
                        }
                    })
                ) { cfg in
                    store.updateRoutineExercise(routineId, slot.index, config: cfg)
                    editing = nil
                }
                .navigationTitle(catalog.name(exId))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { editing = nil } } }
            }
        }
        .sheet(isPresented: $adding) { addSheet() }
        .sheet(item: Binding(get: { replacing.map { Slot(index: $0) } }, set: { replacing = $0?.index })) { slot in
            replaceSheet(slot.index)
        }
        .confirmationDialog("Delete routine?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) {
                store.deleteRoutine(routineId)
                dismiss()
            }
        } message: {
            Text("“\(r.name)” and its exercises will be removed.")
        }
    }

    @ViewBuilder
    private func exerciseRow(_ r: Routine, _ i: Int, _ e: RoutineExercise, line: String, missing: Bool) -> some View {
        let linkedAbove = i > 0 && e.sg != nil && r.ex[i - 1].sg == e.sg
        let linkedBelow = i + 1 < r.ex.count && e.sg != nil && r.ex[i + 1].sg == e.sg
        Button { editing = Slot(index: i) } label: {
            HStack(spacing: 12) {
                ExerciseThumb(exerciseId: e.id, size: 46)
                VStack(alignment: .leading, spacing: 2) {
                    Text(catalog.name(e.id)).foregroundStyle(.primary).lineLimit(2)
                    Text(line).font(.subheadline).foregroundStyle(.secondary)
                    if let note = e.note, !note.isEmpty {
                        Text(note).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    }
                }
                Spacer(minLength: 0)
                if missing {
                    Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
                        .accessibilityLabel(Text("Needs equipment you don’t have"))
                }
                if linkedAbove || linkedBelow {
                    Image(systemName: "link").foregroundStyle(Color.accentColor)
                        .accessibilityLabel(Text("Superset"))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .swipeActions(edge: .leading) {
            if i > 0 {
                Button(linkedAbove ? "Unlink" : "Superset", systemImage: linkedAbove ? "link.badge.plus" : "link") {
                    store.toggleSupersetLink(routineId, i)
                }
                .tint(.indigo)
            }
        }
        .swipeActions(edge: .trailing) {
            Button("Remove", systemImage: "trash", role: .destructive) { store.removeRoutineExercise(routineId, i) }
        }
        .contextMenu {
            Button("Move up", systemImage: "arrow.up") { store.moveRoutineExercise(routineId, i, -1) }
            Button("Move down", systemImage: "arrow.down") { store.moveRoutineExercise(routineId, i, 1) }
            if i > 0 {
                Button(linkedAbove ? "Unlink from above" : "Superset with above", systemImage: "link") {
                    store.toggleSupersetLink(routineId, i)
                }
            }
            Button("Replace exercise", systemImage: "arrow.triangle.2.circlepath") { replacing = i }
        }
    }

    /// SwiftUI's drop destination as openGym's unit slot: supersets move whole and are never split.
    private func slot(_ r: Routine, source: Int, destination: Int) -> Int {
        let units = supersetUnits(r.ex)
        guard let sourceUnit = units.firstIndex(where: { $0.contains(source) }) else { return 0 }
        let remaining = units.enumerated().filter { $0.offset != sourceUnit }.map(\.element)
        return remaining.filter { ($0.first ?? 0) < destination }.count
    }

    private func supersetUnits(_ ex: [RoutineExercise]) -> [[Int]] {
        var units: [[Int]] = []
        for (i, e) in ex.enumerated() {
            if i > 0, let sg = e.sg, ex[i - 1].sg == sg { units[units.count - 1].append(i) } else { units.append([i]) }
        }
        return units
    }

    private func addSheet() -> some View {
        ExercisePickerSheet(title: "Add exercise") { id in
            store.addRoutineExercise(routineId, id)
        } configure: { id in
            ExerciseConfigForm(exerciseId: id, routineId: routineId,
                               start: store.configStart(id, existing: nil, routine: routineId),
                               saveLabel: "Add to routine") { cfg in
                store.addRoutineExercise(routineId, id, config: cfg)
                adding = false
            }
        }
    }

    /// Replace (#110): the new exercise opens at the slot's own numbers.
    private func replaceSheet(_ index: Int) -> some View {
        ExercisePickerSheet(title: "Replace exercise") { id in
            store.replaceRoutineExercise(routineId, index, with: id)
            replacing = nil
        } configure: { id in
            ExerciseConfigForm(exerciseId: id, routineId: routineId,
                               start: store.configStart(id, existing: store.replacementFor(routineId, index, with: id), routine: routineId),
                               saveLabel: "Replace") { cfg in
                store.replaceRoutineExercise(routineId, index, with: id, config: cfg)
                replacing = nil
            }
        }
    }
}
