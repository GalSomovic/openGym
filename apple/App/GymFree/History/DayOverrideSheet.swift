import OpenGymCore
import SwiftUI

/// sheets.jsx DayOverride: one date changed. Rest or skip it, train another routine, go back to
/// the weekly plan, or log a planned day that went by without a workout.
struct DayOverrideSheet: View {
    let iso: String
    @Environment(GymStore.self) private var store
    @Environment(TodayRouter.self) private var router
    @Environment(WorkoutSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            if let info = store.dayInfo(iso, today: Day.today) {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 4) {
                                Text("Weekly plan:")
                                Text(info.weekly)
                                if info.changed { Text("· changed for this day").foregroundStyle(.orange) }
                            }
                            .font(.subheadline)
                            Text("Sick, missed a day or want a different session? Pick what to train instead.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        if info.missed {
                            Button {
                                router.sheet = .logPast(LogPastInitial(iso: iso, routineIds: info.planned))
                            } label: {
                                Label("Log this workout", systemImage: "checkmark.circle")
                                    .frame(maxWidth: .infinity).fontWeight(.semibold)
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(store.active != nil)
                        }
                    }
                    if !info.workouts.isEmpty {
                        Section("Logged") {
                            ForEach(store.historyRows().filter { info.workouts.contains($0.key) }) { row in
                                Button { router.show(.workout(row.key)) } label: { WorkoutRowView(row: row) }
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                    Section {
                        ForEach(store.routines) { r in
                            Button { set(r.id) } label: {
                                HStack(spacing: 12) {
                                    RoutineIcon(emoji: r.emoji)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(r.name).foregroundStyle(.primary)
                                        Text(Fmt.exercises(r.ex.count)).font(.subheadline).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if info.planned.contains(r.id) { Image(systemName: "checkmark").foregroundStyle(.tint) }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        Button { set("rest") } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "moon.fill").foregroundStyle(.secondary).frame(width: 34)
                                Text("Rest / skip this day").foregroundStyle(.primary)
                                Spacer()
                                if info.planned.isEmpty { Image(systemName: "checkmark").foregroundStyle(.tint) }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if info.changed {
                            Button { set("") } label: {
                                Label("Back to weekly plan", systemImage: "arrow.uturn.backward")
                            }
                        }
                    }
                }
                .navigationTitle(info.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func set(_ value: String) {
        store.setDayOverride(iso, value)
        session.toast = store.dayChangeText(iso, value)
        dismiss()
    }
}

/// sheets.jsx WorkoutRow: a workout in a list, with its records.
struct WorkoutRowView: View {
    let row: HistoryRow

    var body: some View {
        HStack(spacing: 12) {
            RoutineIcon(emoji: row.emoji, symbol: row.activity.flatMap(ActivityKind.init(rawValue:))?.symbol)
            VStack(alignment: .leading, spacing: 2) {
                Text(row.name).foregroundStyle(.primary)
                Text(row.line).font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 4)
            if row.prs > 0 { PRBadge(text: "\(row.prs) PR") }
        }
        .contentShape(Rectangle())
    }
}

struct PRBadge: View {
    var text = "PR"

    var body: some View {
        Label(text, systemImage: "trophy.fill")
            .labelStyle(.titleAndIcon)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.yellow)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(.yellow.opacity(0.15), in: .capsule)
            .fixedSize()
    }
}
