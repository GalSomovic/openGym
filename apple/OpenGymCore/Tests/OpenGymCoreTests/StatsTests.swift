import Foundation
import Testing
@testable import OpenGymCore

private let profile = """
{"routines": [{"id": "r1", "name": "Push", "emoji": "dumbbell", "ex": [{"id": "0025", "sets": 2, "reps": 5, "weight": 60}]}],
 "week": {"1": ["r1"]}}
"""

@Suite(.serialized) @MainActor
struct StatsTests {
    private func logged() throws -> GymStore {
        let store = GymStore(storage: MemoryStorage(profile))
        for (iso, w) in [("2026-09-21", 60.0), ("2026-09-28", 65.0)] {
            store.beginBackfill(iso: iso, time: "18:00", durationMin: 45, routineIds: ["r1"], replaceId: nil, freestyleName: "Freestyle")
            store.setField(0, 0, "w", w)
            store.setField(0, 1, "w", w)
            store.markAllDone()
            try #require(store.finishWorkout() != nil)
        }
        return store
    }

    @Test func overviewAndProgressDecode() throws {
        let store = try logged()
        let o = try #require(store.statsOverview(today: "2026-10-05"))
        #expect(o.workouts == 2)
        #expect(o.recent.count == 2)
        #expect(store.progressExercises().map(\.id) == ["0025"])
        #expect(store.progressExercises("squat").isEmpty)
        let p = try #require(store.exerciseProgress("0025"))
        #expect(p.top.map(\.y) == [60, 65])
        #expect(p.e1rm.count == 2)
        #expect(p.best.top == "65 kg")
        #expect(p.metrics.compactMap(\.value.string) == ["top", "e1rm"])
        #expect(p.bestSet?.text.contains("65") == true)
        let h = try #require(store.exerciseHistorySheet("0025"))
        #expect(h.total == 2)
        #expect(h.points.count == 2)
    }

    @Test func heatmapEffortOneRMAndBalanceDecode() throws {
        let store = try logged()
        let map = try #require(store.heatmap())
        #expect(map.weeks.count == 53)
        #expect(map.metric == "time")
        store.setHeatmapMetric("vol")
        #expect(store.heatmap()?.metric == "vol")
        #expect(store.effortCard(days: 0)?.rated == 0)

        let calc = try #require(store.oneRM("0025"))
        #expect(calc.fromLog != nil)
        #expect(calc.table.count == 12)
        #expect(store.oneRM("0025", weight: 100, reps: 1)?.estimate == 100)
        #expect(store.oneRM("0025", weight: 100, reps: 20)?.estimate == nil)

        let b = try #require(store.structuralBalance())
        #expect(!b.rows.isEmpty)
        store.setBalanceTemplate("atg")
        #expect(store.structuralBalance()?.template == "atg")
        let role = try #require(store.structuralBalance()?.rows.first?.role)
        store.setBalanceExercise(role, "0025")
        #expect(store.structuralBalance()?.rows.first?.custom == true)
    }
}
