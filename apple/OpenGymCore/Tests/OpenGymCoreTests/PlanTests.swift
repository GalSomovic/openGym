import Foundation
import Testing
@testable import OpenGymCore

@Suite(.serialized) @MainActor
struct PlanTests {
    @Test func libraryListsAndSearches() throws {
        let store = GymStore(storage: MemoryStorage())
        let all = store.catalogue()
        #expect(all.count > 1300)
        #expect(all.first { $0.id == "0025" }?.displayName == "Barbell Bench Press")
        let res = try #require(store.browse(query: "bench press", bodyPart: "", equipment: "", showAll: false))
        #expect(res.ids.contains("0025"))
        let detail = try #require(store.exerciseDetail("0025"))
        #expect(!detail.st.isEmpty)
        store.toggleFavourite("0025")
        #expect(store.exerciseDetail("0025")?.fav == true)
    }

    @Test func buildsARoutineThroughTheSettingsSheet() throws {
        let store = GymStore(storage: MemoryStorage())
        let rid = try #require(store.addRoutine(name: "Push"))
        var draft = store.configStart("0025", existing: nil, routine: rid)
        draft["sets"] = .number(4); draft["reps"] = .number(6); draft["weight"] = .number(70)
        let info = try #require(store.configInfo("0025", draft, routine: rid))
        #expect(info.mode == "reps" && info.stepValid)
        let cfg = try #require(store.configToSave("0025", draft, routine: rid))
        store.addRoutineExercise(rid, "0025", config: cfg)
        store.addRoutineExercise(rid, "0032")
        #expect(store.routines.first?.ex.map(\.id) == ["0025", "0032"])
        #expect(store.routines.first?.ex.first?.sets == 4)
        store.toggleSupersetLink(rid, 1)
        #expect(store.routineConfigs(rid).allSatisfy { $0["sg"] != nil })
        store.assignDay(1, rid)
        #expect(store.week["1"] == [rid])
    }

    @Test func loadsAStarterPlan() {
        let store = GymStore(storage: MemoryStorage())
        #expect(store.starterPlans().map(\.id).contains("ppl"))
        store.loadStarterPlan("ppl")
        #expect(store.routines.count == 3)
        #expect(store.starterPlanConflicts("full-body"))
    }
}
