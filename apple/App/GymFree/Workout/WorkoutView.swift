import OpenGymCore
import SwiftUI

/// The running session (Workout.jsx ActiveWorkout). Cards show one exercise (or superset) at a
/// time with Prev and Next; List and Compact stack the whole session.
struct WorkoutView: View {
    var onSummaryClosed: () -> Void = {}
    @Environment(GymStore.self) private var store
    @Environment(WorkoutSession.self) private var session
    @Environment(ExerciseCatalog.self) private var catalog
    @State private var adding = false
    @State private var finishAsk: FinishCheck?
    @State private var summary: FinishSummary?
    @State private var discardAsk = false
    @State private var renaming = false
    @State private var newName = ""
    @State private var addingRoutine = false

    var body: some View {
        if let a = store.active {
            content(a)
        } else if let summary {
            FinishSummaryView(summary: summary) {
                self.summary = nil
                onSummaryClosed()
            }
        } else {
            Color.clear.onAppear(perform: onSummaryClosed)
        }
    }

    private func layout(_ a: ActiveSession) -> String { a.workoutView ?? store.pick("workoutView", as: String.self) ?? "cards" }

    @ViewBuilder
    private func content(_ a: ActiveSession) -> some View {
        let mode = layout(a)
        let cur = min(max(a.cur, 0), max(0, a.entries.count - 1))
        let unitIdx = a.units.firstIndex { $0.contains(cur) } ?? 0
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header(a)
                    if a.entries.isEmpty {
                        ContentUnavailableView("No exercises yet", systemImage: "dumbbell",
                                               description: Text("Add your first exercise to get going."))
                    } else if mode == "cards" {
                        let unit = a.units[safe: unitIdx] ?? []
                        if unit.count > 1 { SupersetLabel() }
                        ForEach(unit, id: \.self) { i in
                            ExerciseBlockView(entry: i, showDemo: true, compact: unit.count > 1)
                                .id(i)
                        }
                        HStack {
                            Button { store.navigate(-1) } label: { Label("Prev", systemImage: "chevron.backward") }
                                .disabled(unitIdx <= 0)
                            Spacer()
                            Text("\(unitIdx + 1) / \(a.units.count)").font(.footnote).foregroundStyle(.secondary).monospacedDigit()
                            Spacer()
                            Button { store.navigate(1) } label: {
                                Label("Next", systemImage: "chevron.forward").labelStyle(TrailingIconLabelStyle())
                            }
                            .disabled(unitIdx >= a.units.count - 1)
                        }
                        .buttonStyle(.bordered)
                    } else {
                        ForEach(Array(a.units.enumerated()), id: \.offset) { ui, unit in
                            VStack(alignment: .leading, spacing: 14) {
                                if unit.count > 1 { SupersetLabel() }
                                ForEach(unit, id: \.self) { i in
                                    ExerciseBlockView(entry: i, showDemo: mode == "list", compact: mode == "compact").id(i)
                                }
                            }
                            .padding(12)
                            .background(ui == unitIdx ? Color.accentColor.opacity(0.08) : .clear, in: .rect(cornerRadius: 18))
                            .onTapGesture(count: 2) { store.setCurrent(unit[0]) }
                        }
                    }
                    Button { adding = true } label: {
                        Label("Add exercise", systemImage: "plus").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: a.cur) { _, new in
                if mode != "cards" { withAnimation { proxy.scrollTo(new, anchor: .top) } }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if session.rest != nil || session.hold != nil { TimerBar().padding(.horizontal).padding(.bottom, 6) }
        }
        .navigationTitle(a.name ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar(a) }
        .sheet(isPresented: $adding) { addSheet(a) }
        .sheet(isPresented: $addingRoutine) { AddRoutineToSessionSheet() }
        .alert("Rename workout", isPresented: $renaming) {
            TextField("Name", text: $newName)
            Button("Save") { store.renameWorkout(newName) }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Discard workout?", isPresented: $discardAsk, titleVisibility: .visible) {
            Button("Discard", role: .destructive) {
                session.stopRest(); session.cancelHold()
                store.discardWorkout()
            }
        } message: {
            Text("The sets you logged in this session will be lost.")
        }
        .confirmationDialog(finishTitle, isPresented: Binding(get: { finishAsk != nil }, set: { if !$0 { finishAsk = nil } }),
                            titleVisibility: .visible) {
            Button(finishAsk?.done == 0 ? "Finish anyway" : "Finish workout") { finish() }
            Button("Keep going", role: .cancel) {}
        } message: {
            if let f = finishAsk {
                Text(f.done == 0 ? "You haven’t checked off any sets. Finish the workout anyway?"
                     : f.total - f.done == 1 ? "1 set still unchecked. Finish the workout now?"
                     : "\(f.total - f.done) sets still unchecked. Finish the workout now?")
            }
        }
        .alert("Workout complete!", isPresented: Binding(get: { session.completePrompt }, set: { session.completePrompt = $0 })) {
            Button("Finish") { finish() }
            Button("Not yet", role: .cancel) {}
        } message: {
            Text("Every set is done. Finish and save the workout?")
        }
        .overlay(alignment: .top) { ToastView() }
    }

    private var finishTitle: String {
        guard let f = finishAsk else { return "" }
        return f.done == 0 ? String(localized: "Nothing logged yet") : String(localized: "Finish early?")
    }

    private func header(_ a: ActiveSession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if a.isBackfill {
                    Label(a.d, systemImage: "calendar").font(.subheadline).foregroundStyle(.secondary)
                } else {
                    TimelineView(.periodic(from: .now, by: 1)) { ctx in
                        Label(Self.elapsed(from: a.startDate, to: ctx.date), systemImage: "stopwatch")
                            .font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text("\(a.setsDone) / \(a.setsTotal) sets").font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
            }
            ProgressView(value: Double(a.setsDone), total: Double(max(a.setsTotal, 1)))
                .tint(.accentColor)
        }
    }

    static func elapsed(from start: Date, to now: Date) -> String {
        let s = max(0, Int(now.timeIntervalSince(start)))
        return s >= 3600 ? String(format: "%d:%02d:%02d", s / 3600, s / 60 % 60, s % 60) : String(format: "%d:%02d", s / 60, s % 60)
    }

    @ToolbarContentBuilder
    private func toolbar(_ a: ActiveSession) -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button { discardAsk = true } label: { Image(systemName: "xmark") }
                .accessibilityLabel(Text("Discard"))
        }
        ToolbarItem(placement: .primaryAction) {
            Menu {
                if a.isBackfill && !a.entries.isEmpty {
                    Button("Mark all sets done", systemImage: "checkmark.circle") {
                        store.markAllDone()
                        session.completePrompt = true
                    }
                }
                Button("Rename workout", systemImage: "pencil") { newName = a.name ?? ""; renaming = true }
                Button("Add routine", systemImage: "plus.square.on.square") { addingRoutine = true }
                Button("Don’t count for progression", systemImage: "pause.circle") { store.toggleSessionNoProgression() }
                Picker(selection: Binding(get: { layout(a) }, set: { store.setWorkoutView($0) })) {
                    Label("Cards", systemImage: "rectangle.portrait").tag("cards")
                    Label("List", systemImage: "list.bullet").tag("list")
                    Label("Compact", systemImage: "list.dash").tag("compact")
                } label: {
                    Label("Layout", systemImage: "square.grid.2x2")
                }
                .pickerStyle(.menu)
            } label: { Image(systemName: "ellipsis") }
            .accessibilityLabel(Text("More"))
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Finish") {
                guard let f = store.finishCheck() else { return }
                if f.done == 0 || f.done < f.total { finishAsk = f } else { finish() }
            }
            .fontWeight(.semibold)
        }
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Done") { UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil) }
        }
    }

    private func finish() {
        session.stopRest(); session.cancelHold()
        if let s = store.finishWorkout() {
            session.cues.finished()
            summary = s
        }
    }

    private func addSheet(_ a: ActiveSession) -> some View {
        let rid = a.entries[safe: a.cur]?.rid
        return ExercisePickerSheet(title: "Add exercise") { id in
            if let at = store.addExercise(id, config: nil) { session.exerciseInserted(at: at) }
            adding = false
        } configure: { id in
            ExerciseConfigForm(exerciseId: id, routineId: rid,
                               start: store.configStart(id, existing: nil, routine: rid, initial: store.addExerciseSeed(id)),
                               saveLabel: "Add to this workout") { cfg in
                if let at = store.addExercise(id, config: cfg) { session.exerciseInserted(at: at) }
                adding = false
            }
        }
    }
}

private struct SupersetLabel: View {
    var body: some View {
        Label("Superset", systemImage: "link").font(.caption.weight(.semibold)).foregroundStyle(Color.accentColor)
            .textCase(.uppercase)
    }
}

struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) { configuration.title; configuration.icon }
    }
}

/// Header ⋮ → Add routine: another routine's exercises appended to this session.
struct AddRoutineToSessionSheet: View {
    @Environment(GymStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            let inSession = Set(store.active?.routineIds ?? [])
            List(store.routines) { r in
                let disabled = inSession.contains(r.id) || r.ex.isEmpty
                Button {
                    store.addRoutineToSession(r.id)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        RoutineIcon(emoji: r.emoji)
                        VStack(alignment: .leading) {
                            Text(r.name)
                            Text(Fmt.exercises(r.ex.count)).font(.subheadline).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if inSession.contains(r.id) { Text("already added").font(.caption).foregroundStyle(.secondary) }
                        else if r.ex.isEmpty { Text("no exercises").font(.caption).foregroundStyle(.secondary) }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(disabled)
                .opacity(disabled ? 0.5 : 1)
            }
            .navigationTitle("Add routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
        .presentationDetents([.medium, .large])
    }
}

struct ToastView: View {
    @Environment(WorkoutSession.self) private var session

    var body: some View {
        if let text = session.toast {
            Text(text)
                .font(.subheadline.weight(.semibold))
                .padding(.horizontal, 16).padding(.vertical, 10)
                .glassEffect()
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
                .task(id: text) {
                    try? await Task.sleep(for: .seconds(2))
                    withAnimation { session.toast = nil }
                }
        }
    }
}
