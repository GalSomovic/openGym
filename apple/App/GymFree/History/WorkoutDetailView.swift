import OpenGymCore
import SwiftUI

/// sheets.jsx WorkoutDetail: a saved workout's exercises, sets and records, its note, and what can
/// be done with it: edit, move, change its length, save as a routine, copy as text, delete.
struct WorkoutDetailView: View {
    let key: String
    @Environment(GymStore.self) private var store
    @Environment(TodayRouter.self) private var router
    @Environment(WorkoutSession.self) private var session
    @Environment(\.dismiss) private var dismiss
    @State private var note = ""
    @State private var loadedNote: String?
    @State private var editingDate = false
    @State private var editingDuration = false
    @State private var askSaveRoutine = false
    @State private var askDelete = false
    @FocusState private var noteFocused: Bool

    var body: some View {
        if let w = store.workoutDetail(key) {
            content(w)
        } else {
            ContentUnavailableView("Workout deleted", systemImage: "trash")
        }
    }

    private func content(_ w: WorkoutDetail) -> some View {
        List {
            Section {
                Text(w.line).font(.subheadline).foregroundStyle(.secondary)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
            }
            ForEach(Array(w.sections.enumerated()), id: \.offset) { _, section in
                Section {
                    ForEach(Array(section.units.enumerated()), id: \.offset) { _, unit in
                        if unit.count > 1 {
                            Label("Superset", systemImage: "link")
                                .font(.caption.weight(.semibold)).foregroundStyle(Color.accentColor).textCase(.uppercase)
                        }
                        ForEach(unit, id: \.idx) { e in
                            NavigationLink(value: TodayRouter.Route.exercise(e.id)) { entryRow(e, inSuperset: unit.count > 1) }
                        }
                    }
                } header: {
                    if let title = section.title {
                        HStack(spacing: 6) {
                            if let emoji = section.emoji { Image(systemName: Glyphs.symbol(emoji)) }
                            Text(title)
                            Spacer()
                            if let summary = section.summary { Text(summary).textCase(nil) }
                        }
                    }
                }
            }
            Section("Session note") {
                TextField("How the session went as a whole.", text: $note, axis: .vertical)
                    .lineLimit(2...6)
                    .focused($noteFocused)
                    .onChange(of: noteFocused) { _, focused in if !focused { saveNote() } }
                    .accessibilityIdentifier("detail.note")
            }
            Section {
                Button("Edit workout", systemImage: "pencil") {
                    saveNote()
                    store.editWorkout(key)
                }
                .disabled(w.busy)
                Button("Change date & time", systemImage: "calendar") { saveNote(); editingDate = true }
                Button("Change duration", systemImage: "timer") { saveNote(); editingDuration = true }
                Button("Save as routine", systemImage: "plus.square.on.square") { askSaveRoutine = true }
                Button("Copy as text", systemImage: "doc.on.doc") { copy() }
            } footer: {
                if w.busy { Text("Finish the current workout first.") }
            }
            Section {
                Button("Delete workout", systemImage: "trash", role: .destructive) { askDelete = true }
            }
        }
        .navigationTitle(w.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if loadedNote == nil { note = w.note; loadedNote = w.note } }
        .onDisappear { saveNote() }
        .sheet(isPresented: $editingDate) { WorkoutDateSheet(key: key, date: w.d, time: w.startTime) }
        .sheet(isPresented: $editingDuration) { WorkoutDurationSheet(key: key, minutes: w.durationMin) }
        .confirmationDialog("Save as routine?", isPresented: $askSaveRoutine, titleVisibility: .visible) {
            Button("Save") {
                if store.saveWorkoutAsRoutine(key) != nil {
                    session.toast = String(localized: "Saved as routine “\(w.name)”")
                    router.openTab(.plan)
                }
            }
        } message: {
            Text("Create an independent routine from these exercise targets. Your workout history is kept.")
        }
        .confirmationDialog("Delete workout?", isPresented: $askDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                loadedNote = note   // nothing left to save
                store.deleteWorkout(key)
                session.toast = String(localized: "Workout deleted")
                dismiss()
            }
        } message: {
            Text("This removes it from your history for good.")
        }
    }

    private func entryRow(_ e: DetailEntry, inSuperset: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if inSuperset { Capsule().fill(Color.accentColor).frame(width: 3) }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(e.name).fontWeight(.semibold)
                    if e.pr { PRBadge() }
                }
                Text(e.sets).font(.subheadline).foregroundStyle(.secondary)
                if let n = e.note, !n.isEmpty {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        if e.notePin { Image(systemName: "flag.fill").foregroundStyle(.yellow) }
                        Text(n)
                    }
                    .font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    /// Only an actual change is written (and stamped for the sync).
    private func saveNote() {
        guard let loaded = loadedNote, note.trimmingCharacters(in: .whitespacesAndNewlines) != loaded else { return }
        store.setWorkoutNote(key, note)
        loadedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Copied with the note as it stands in the box, which may not be saved yet.
    private func copy() {
        if let text = store.workoutText(key, note: note) {
            UIPasteboard.general.string = text
            session.toast = String(localized: "Copied")
        } else {
            session.toast = String(localized: "Could not copy")
        }
    }
}

/// sheets.jsx WorkoutDateEdit: when it happened. The session keeps its length; records are worked
/// out again from the new order.
struct WorkoutDateSheet: View {
    let key: String
    @State var date: String
    @State var time: String
    @Environment(GymStore.self) private var store
    @Environment(WorkoutSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: Binding(get: { Day.date(date) }, set: { date = Fmt.todayISO($0) }),
                               in: ...Day.endOfToday, displayedComponents: .date)
                    DatePicker("Start time", selection: Binding(get: { Day.time(time) }, set: { time = Day.hhmm($0) }),
                               displayedComponents: .hourAndMinute)
                } footer: {
                    Text("The session keeps its length. Personal records are worked out again from the new order.")
                }
            }
            .navigationTitle("Change date & time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if store.moveWorkout(key, to: date, time: time) { session.toast = String(localized: "Workout moved") }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

/// sheets.jsx WorkoutDurationEdit: how long it really took. The start and the sets stay.
struct WorkoutDurationSheet: View {
    let key: String
    @State var minutes: Int
    @Environment(GymStore.self) private var store
    @Environment(WorkoutSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NumberStepper(label: "Duration", value: Binding(get: { Double(minutes) }, set: { minutes = Int($0.rounded()) }),
                                  step: 5, range: 0...1440, unit: String(localized: "min"))
                } footer: {
                    if minutes < 1 {
                        Text("Enter how long it took — at least 1 minute.").foregroundStyle(.red)
                    } else {
                        Text("Forgot to finish on time? Set how long the session really took. It keeps its start time and its sets.")
                    }
                }
            }
            .navigationTitle("Change duration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if store.setWorkoutDuration(key, minutes: minutes) { session.toast = String(localized: "Duration changed") }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(minutes < 1)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
