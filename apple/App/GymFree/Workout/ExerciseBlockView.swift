import OpenGymCore
import SwiftUI

/// One exercise in the running session (Workout.jsx ExerciseBlock): the demo, the notes and
/// plan lines, the set rows, and everything else behind one "more" menu.
struct ExerciseBlockView: View {
    let entry: Int
    var showDemo = true
    var compact = false
    @Environment(GymStore.self) private var store
    @Environment(WorkoutSession.self) private var session
    @Environment(ExerciseCatalog.self) private var catalog
    @State private var noteEditing = false
    @State private var swapping = false
    @State private var progressionEditing = false
    @State private var historyShown = false
    @State private var removeConfirm = false
    @State private var demoHidden = false

    var body: some View {
        if let a = store.active, let e = a.entries[safe: entry], let view = store.entryView(entry) {
            content(a, e, view)
        }
    }

    @ViewBuilder
    private func content(_ a: ActiveSession, _ e: SessionEntry, _ view: EntryView) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if showDemo && !demoHidden {
                ExerciseAnimation(exerciseId: e.id, toggle: true)
                    .frame(maxWidth: compact ? 180 : 300, maxHeight: compact ? 180 : 260)
                    .frame(maxWidth: .infinity)
                    .clipShape(.rect(cornerRadius: 16))
                    .overlay(alignment: .topTrailing) {
                        Button { withAnimation { demoHidden = true } } label: {
                            Image(systemName: "chevron.up.circle.fill").font(.title3)
                                .symbolRenderingMode(.palette).foregroundStyle(.white, .black.opacity(0.4))
                        }
                        .padding(8)
                        .accessibilityLabel(Text("Hide demonstration"))
                    }
            }
            header(a, e, view)
            if !compact { details(e, view) }
            setTable(e, view)
            HStack {
                Button("Add set", systemImage: "plus") { store.addSet(entry) }
                Spacer()
                if demoHidden && showDemo {
                    Button("Show demo", systemImage: "play.rectangle") { withAnimation { demoHidden = false } }
                }
            }
            .font(.subheadline)
            .buttonStyle(.borderless)
        }
        .sheet(isPresented: $noteEditing) { ExerciseNoteSheet(entry: entry, note: e.note ?? "", pinned: e.notePin == true) }
        .sheet(isPresented: $swapping) { swapSheet(e) }
        .sheet(isPresented: $progressionEditing) { progressionSheet(e) }
        .sheet(isPresented: $historyShown) { ExerciseHistorySheet(exerciseId: e.id) }
        .confirmationDialog("Remove \(catalog.name(e.id))?", isPresented: $removeConfirm, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                session.exerciseRemoved(entry)
                store.removeExercise(entry)
            }
        } message: {
            Text(e.sets.contains(where: \.isDone)
                 ? "The sets you logged for this exercise in this session will be lost."
                 : "This removes the exercise from your current session.")
        }
    }

    private func header(_ a: ActiveSession, _ e: SessionEntry, _ view: EntryView) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(catalog.name(e.id))
                .font(compact ? .headline : .title3.weight(.semibold))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            if e.note?.isEmpty == false {
                Button { noteEditing = true } label: { Image(systemName: "pencil") }
                    .accessibilityLabel(Text("Note"))
            }
            moreMenu(a, e, view)
        }
    }

    private func moreMenu(_ a: ActiveSession, _ e: SessionEntry, _ view: EntryView) -> some View {
        let unitOf = a.units.first { $0.contains(entry) } ?? [entry]
        let single = unitOf.count == 1
        let editing = a.editingWorkoutId != nil
        return Menu {
            Button(e.note?.isEmpty == false ? "Edit note" : "Add note", systemImage: "pencil") { noteEditing = true }
            Button("History", systemImage: "clock.arrow.circlepath") { historyShown = true }
            if !editing {
                Button("Progression settings", systemImage: "chart.line.uptrend.xyaxis") { progressionEditing = true }
            }
            if !view.routineKeepsOut {
                Toggle(isOn: Binding(get: { e.noProg == true }, set: { store.setExerciseNoProgression(entry, $0) })) {
                    Label("Don’t count for progression", systemImage: "pause.circle")
                }
            }
            Button("Add warm-up set", systemImage: "flame") { store.addWarmup(entry) }
            if single && entry > 0 {
                Button("Make superset with previous", systemImage: "link") { store.pair(entry - 1, entry) }
            }
            if single && entry < a.entries.count - 1 {
                Button("Make superset with next", systemImage: "link") { store.pair(entry, entry + 1) }
            }
            if !single {
                Button("Split superset", systemImage: "link.badge.plus") { store.unpair(entry) }
            }
            Divider()
            Button("Swap exercise", systemImage: "arrow.triangle.2.circlepath") { swapping = true }
                .disabled(session.hold != nil)
            Button("Move up", systemImage: "arrow.up") { session.exercisesReordered(store.move(entry, -1)) }
                .disabled(session.hold != nil || !store.canMove(entry, -1))
            Button("Move down", systemImage: "arrow.down") { session.exercisesReordered(store.move(entry, 1)) }
                .disabled(session.hold != nil || !store.canMove(entry, 1))
            Button("Remove exercise", systemImage: "trash", role: .destructive) { removeConfirm = true }
                .disabled(session.hold != nil)
        } label: {
            Image(systemName: "ellipsis.circle").font(.title3)
        }
        .accessibilityLabel(Text("More"))
    }

    @ViewBuilder
    private func details(_ e: SessionEntry, _ view: EntryView) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if view.noProg {
                HStack {
                    Label("Not counted for progression", systemImage: "pause.circle").foregroundStyle(.orange)
                    if !view.routineKeepsOut {
                        Button("Undo") { store.setExerciseNoProgression(entry, false) }.buttonStyle(.bordered).controlSize(.mini)
                    }
                }
                .font(.footnote)
            }
            let tags = [view.cardio ? String(localized: "Cardio") : nil,
                        !view.cardio && !view.timed && view.perSide ? String(localized: "Per side") : nil,
                        catalog[e.id].map { catalog.muscleName($0.tg ?? $0.bp) },
                        catalog[e.id]?.eq?.capitalizedWords,
                        view.bestText].compactMap { $0 }
            FlowTags(tags: tags)
            if let n = view.routineNote { NoteLine(text: n, icon: "list.clipboard") }
            if let n = view.standingNote { NoteLine(text: n, icon: "info.circle") }
            if let n = view.pinnedNote { NoteLine(text: n, icon: "flag.fill", tint: .yellow) }
            if let n = view.note { NoteLine(text: n, icon: "pencil") }
            if let plan = view.planLine {
                Text(plan).font(.footnote).foregroundStyle(.secondary)
            }
            if let ref = view.refText {
                Button { store.toggleLogRef() } label: {
                    HStack(spacing: 4) {
                        Text(ref).multilineTextAlignment(.leading)
                        Image(systemName: "arrow.left.arrow.right").font(.caption2)
                    }
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityHint(Text(view.refAction))
            }
            if let g = view.guidance, store.active?.editingWorkoutId == nil {
                Button { progressionEditing = true } label: {
                    Label {
                        Text("**\(g.label)** · \(g.why)").multilineTextAlignment(.leading)
                    } icon: {
                        Image(systemName: g.kind == "up" ? "arrow.up" : g.kind == "deload" ? "arrow.down" : "lightbulb")
                    }
                    .font(.footnote)
                    .foregroundStyle(g.kind == "deload" ? Color.orange : Color.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func setTable(_ e: SessionEntry, _ view: EntryView) -> some View {
        VStack(spacing: 2) {
            HStack(spacing: 8) {
                Color.clear.frame(width: view.perSide ? 48 : 26, height: 1)
                ForEach(Array(view.cols.enumerated()), id: \.offset) { _, col in
                    if let col {
                        Text(col.hd).frame(maxWidth: col.eff == nil ? .infinity : 46)
                    }
                }
                if view.timed { Color.clear.frame(width: 34, height: 1) }
                Color.clear.frame(width: 30, height: 1)
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(.uppercase)
            ForEach(Array(e.sets.enumerated()), id: \.offset) { i, row in
                if let info = view.rows[safe: i] {
                    if info.firstWarmup {
                        Text("Warm-up").font(.caption.weight(.semibold)).foregroundStyle(.orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if info.sepBefore { Divider().padding(.vertical, 2) }
                    SetRowView(entry: entry, index: i, row: row, info: info, view: view)
                }
            }
        }
        .padding(10)
        .background(.background.secondary, in: .rect(cornerRadius: 14))
    }

    private func swapSheet(_ e: SessionEntry) -> some View {
        ExercisePickerSheet(title: "Swap exercise") { id in
            swap(to: id, config: nil)
        } configure: { id in
            ExerciseConfigForm(exerciseId: id, routineId: e.rid,
                               start: store.configStart(id, existing: nil, routine: e.rid),
                               saveLabel: "Use in this workout") { cfg in
                swap(to: id, config: cfg)
            }
        }
    }

    @State private var pendingSwap: (id: String, config: ExerciseConfig?)?

    private func swap(to id: String, config: ExerciseConfig?) {
        swapping = false
        let res = store.swapExercise(entry, to: id, config: config?.anyObject)
        if res?.needsConfirmation == true {
            // Logged sets are never relabelled: the replacement goes in beside them.
            let r = store.swapExercise(entry, to: id, config: config?.anyObject, loggedConfirmed: true,
                                       groupDisposition: res?.grouped == true ? "keep" : nil)
            if r?.inserted == true, let at = r?.index { session.exerciseInserted(at: at) }
        }
    }

    private func progressionSheet(_ e: SessionEntry) -> some View {
        NavigationStack {
            if let start = store.progressionStart(entry) {
                ExerciseConfigForm(exerciseId: e.id, routineId: start.routineId,
                                   start: store.configStart(e.id, existing: start.config, routine: start.routineId),
                                   saveLabel: "Save") { cfg in
                    store.applyProgressionSettings(entry, cfg)
                    progressionEditing = false
                }
                .navigationTitle(catalog.name(e.id))
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { progressionEditing = false } } }
            }
        }
    }
}

struct NoteLine: View {
    let text: String
    let icon: String
    var tint: Color = .secondary

    var body: some View {
        Label(text, systemImage: icon)
            .font(.footnote)
            .foregroundStyle(tint)
    }
}

/// Today's note on an exercise, and whether to see it again next time.
struct ExerciseNoteSheet: View {
    let entry: Int
    @State var note: String
    @State var pinned: Bool
    @Environment(GymStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                TextField("How did it go? Anything to remember?", text: $note, axis: .vertical)
                    .lineLimit(3...8)
                Toggle("Show it next time", isOn: $pinned)
            }
            .navigationTitle("Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        store.setExerciseNote(entry, note, pinned: pinned)
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

/// The exercise's past sessions (lib/exercise-history.js).
struct ExerciseHistorySheet: View {
    let exerciseId: String
    @Environment(GymStore.self) private var store
    @Environment(ExerciseCatalog.self) private var catalog
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            let sessions = store.exerciseHistory(exerciseId)
            List {
                if sessions.isEmpty {
                    ContentUnavailableView("No history yet", systemImage: "clock",
                                           description: Text("Sessions with this exercise show up here."))
                }
                ForEach(Array(sessions.enumerated()), id: \.offset) { _, s in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(s.title).font(.subheadline.weight(.semibold))
                        Text(s.sets).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(catalog.name(exerciseId))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
