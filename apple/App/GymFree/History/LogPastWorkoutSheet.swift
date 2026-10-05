import OpenGymCore
import SwiftUI

/// sheets.jsx LogPastWorkout: a session that happened without the app, logged on the usual
/// workout screen without timers. From a missed day of the plan it opens on that day with the
/// day's routines picked; a day that already has a workout asks to replace it or add a second.
struct LogPastWorkoutSheet: View {
    let initial: LogPastInitial?
    @Environment(GymStore.self) private var store
    @Environment(TodayRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var date = Fmt.todayISO(Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now)
    @State private var time = "18:00"
    @State private var minutes = 60
    @State private var routineId = ""
    @State private var sameDay: [Workout] = []
    @State private var loaded = false

    /// The planned routines of a combined day, offered as the one session the day plans.
    private static let plannedDay = "__planned-day"
    private var planned: [String] { (initial?.routineIds ?? []).filter { id in store.routines.contains { $0.id == id } } }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: Binding(get: { Day.date(date) }, set: { date = Fmt.todayISO($0) }),
                               in: ...Day.endOfToday, displayedComponents: .date)
                    DatePicker("Start time", selection: Binding(get: { Day.time(time) }, set: { time = Day.hhmm($0) }),
                               displayedComponents: .hourAndMinute)
                    NumberStepper(label: "Duration", value: Binding(get: { Double(minutes) }, set: { minutes = Int($0.rounded()) }),
                                  step: 5, range: 0...1440, unit: String(localized: "min"))
                } footer: {
                    if minutes < 1 { Text("Enter how long it took — at least 1 minute.").foregroundStyle(.red) }
                }
                Section {
                    Picker("Routine", selection: $routineId) {
                        Text("Freestyle").tag("")
                        if planned.count > 1 { Text(store.sessionName(planned)).tag(Self.plannedDay) }
                        ForEach(store.routines) { r in Text(r.name).tag(r.id) }
                    }
                } footer: {
                    Text("Logged on the usual workout screen, without timers.")
                }
            }
            .navigationTitle("Log a past workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Continue") { submit() }
                        .fontWeight(.semibold)
                        .disabled(minutes < 1 || date > Day.today)
                }
            }
            .confirmationDialog(Text(Day.date(date), format: .dateTime.weekday(.abbreviated).day().month()),
                                isPresented: Binding(get: { !sameDay.isEmpty }, set: { if !$0 { sameDay = [] } }),
                                titleVisibility: .visible) {
                ForEach(sameDay) { w in
                    Button(sameDay.count > 1 ? "Replace · \(w.name ?? "")" : "Replace", role: .destructive) { go(replacing: w.id) }
                }
                Button("Add as second workout") { go(replacing: nil) }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("There is already a workout on that day.")
            }
            .onAppear {
                guard !loaded else { return }
                loaded = true
                if let initial { date = initial.iso }
                routineId = planned.count > 1 ? Self.plannedDay : planned.first ?? ""
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func submit() {
        let existing = store.workouts(on: date)
        if existing.isEmpty { go(replacing: nil) } else { sameDay = existing }
    }

    private func go(replacing id: String?) {
        let ids = routineId == Self.plannedDay ? planned : routineId.isEmpty ? [] : [routineId]
        router.sheet = nil
        store.beginBackfill(iso: date, time: time, durationMin: max(1, minutes), routineIds: ids,
                            replaceId: id, freestyleName: String(localized: "Freestyle"))
    }
}
