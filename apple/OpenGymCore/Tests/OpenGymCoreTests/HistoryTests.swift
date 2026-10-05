import Foundation
import Testing
@testable import OpenGymCore

private let profile = """
{"routines": [{"id": "r1", "name": "Push", "emoji": "dumbbell", "ex": [{"id": "0025", "sets": 2, "reps": 5, "weight": 60}]}],
 "week": {"1": ["r1"]}}
"""

@Suite(.serialized) @MainActor
struct HistoryTests {
    @Test func aFinishedWorkoutIsInHistoryAndCanBeEdited() throws {
        let store = GymStore(storage: MemoryStorage(profile))
        store.beginBackfill(iso: "2026-09-28", time: "18:00", durationMin: 50, routineIds: ["r1"], replaceId: nil, freestyleName: "Freestyle")
        store.markAllDone()
        try #require(store.finishWorkout() != nil)
        let row = try #require(store.historyRows().first)
        #expect(row.name == "Push")
        let detail = try #require(store.workoutDetail(row.key))
        #expect(detail.durationMin == 50)
        #expect(detail.sections.first?.units.first?.first?.sets == "60×5  ·  60×5")

        store.setWorkoutNote(row.key, "solid")
        #expect(store.workoutDetail(row.key)?.note == "solid")
        #expect(store.setWorkoutDuration(row.key, minutes: 65))
        #expect(!store.moveWorkout(row.key, to: "2999-01-01", time: "18:00"))
        #expect(store.lastError != nil)

        #expect(store.editWorkout(row.key))
        #expect(store.active?.editingWorkoutId == row.key)
        #expect(store.workoutEditUnchanged())
        store.setField(0, 0, "w", 65)
        #expect(store.saveWorkoutEdit()?.saved == true)
        #expect(store.active == nil)
        #expect(store.workouts.first?.entries.first?.sets.first?.w == 65)

        let rid = try #require(store.saveWorkoutAsRoutine(row.key))
        #expect(store.routines.contains { $0.id == rid })
        #expect(store.workoutText(row.key, note: nil)?.contains("Barbell Bench Press") == true)
        store.deleteWorkout(row.key)
        #expect(store.historyRows().isEmpty)
    }

    @Test func bodyWeightIsLoggedAndShown() throws {
        let store = GymStore(storage: MemoryStorage(profile))
        #expect(store.weightCard()?.last == nil)
        #expect(store.logWeight(81.04) == 81)
        let card = try #require(store.weightCard())
        #expect(card.last?.w == 81)
        #expect(store.setWeightGoal(78)?.contains("78") == true)
        #expect(store.weightCard()?.goal == 78)
        #expect(store.weighIns()?.count == 1)
        #expect(store.weightSeries().map(\.w) == [81])
        store.deleteWeighIn(Fmt.today)
        #expect(store.weightCard()?.last == nil)
    }

    @Test func theWeekStripAndTheCalendar() throws {
        let store = GymStore(storage: MemoryStorage(profile))
        let strip = try #require(store.weekStrip(offset: 0, today: "2026-10-05"))
        #expect(strip.days.count == 7)
        #expect(strip.days[0].dot == "plan" && strip.days[0].today)
        #expect(store.todayInfo("2026-10-06")?.next?.contains("Push") == true)
        #expect(store.dayInfo("2026-09-28", today: "2026-10-05")?.missed == true)
        let month = try #require(store.calendarMonth(year: 2026, month: 9, today: "2026-10-05"))
        #expect(month.days.count == 31 && month.blanks == 3)
    }
}

private enum Fmt {
    static var today: String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }
}
