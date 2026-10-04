import Foundation
import Testing
@testable import OpenGymCore

/// Keeps the profile in memory, like the file would.
final class MemoryStorage: StateStorage, @unchecked Sendable {
    private let lock = NSLock()
    private var json: String?
    init(_ json: String? = nil) { self.json = json }
    func read() throws -> String? { lock.withLock { json } }
    func write(_ json: String) throws { lock.withLock { self.json = json } }
    var saved: String? { lock.withLock { json } }
}

private let profile = """
{"restSec": 75, "routines": [
  {"id": "r1", "name": "Push", "emoji": "dumbbell", "ex": [{"id": "0025", "sets": 3, "reps": 5, "weight": 60}]},
  {"id": "r2", "name": "Pull", "emoji": "dumbbell", "ex": [{"id": "0032", "sets": 2, "reps": 5, "weight": 100}]}
]}
"""

// The engine holds one profile, so these run one at a time.
@Suite(.serialized) @MainActor
struct GymStoreTests {
    @Test func loadsASavedProfile() {
        let store = GymStore(storage: MemoryStorage(profile))
        #expect(store.routines.map(\.name) == ["Push", "Pull"])
        #expect(store.pick("restSec", as: Double.self) == 75)
        #expect(store.active == nil)
    }

    @Test func startsANewProfileFromOpenGymsDefaults() {
        let store = GymStore(storage: MemoryStorage())
        #expect(store.pick("unit", as: String.self) == "kg")
        #expect(store.pick("restSec", as: Double.self) == 90)
        #expect(store.routines.isEmpty)
    }

    @Test func runsAWholeSessionAndSavesIt() throws {
        let storage = MemoryStorage(profile)
        let store = GymStore(storage: storage)
        store.beginWorkout(routineIds: ["r1"], bodyWeight: 80, freestyleName: "Freestyle")
        let active = try #require(store.active)
        #expect(active.name == "Push")
        #expect(active.entries.count == 1)
        #expect(active.setsTotal == 3)

        let first = try #require(store.toggleSet(0, 0, timerRunning: false))
        #expect(first.checked && first.beep)
        #expect(first.rest == RestRequest(sec: 75, forIdx: 0))
        store.setField(0, 1, "w", 62.5)
        #expect(store.active?.entries[0].sets.map(\.w) == [60, 62.5, 62.5])
        store.toggleSet(0, 1, timerRunning: true)
        let last = try #require(store.toggleSet(0, 2, timerRunning: true))
        #expect(last.complete)
        #expect(store.finishCheck() == FinishCheck(done: 3, total: 3))

        let summary = try #require(store.finishWorkout())
        #expect(summary.workout.entries.first?.topW == 62.5)
        #expect(summary.prs == ["0025"])
        #expect(store.active == nil)
        #expect(store.workouts.count == 1)

        store.saveNow()
        let saved = try #require(storage.saved)
        let json = try #require(try JSONSerialization.jsonObject(with: Data(saved.utf8)) as? [String: Any])
        #expect((json["workouts"] as? [Any])?.count == 1)
        #expect(json["active"] is NSNull)
    }

    @Test func keepsAnUnreadableProfileAside() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("gym_state_v1.json")
        try Data("{not json".utf8).write(to: url)
        let store = GymStore(storage: FileStateStorage(url: url))
        #expect(store.lastError != nil)
        #expect(store.routines.isEmpty)
        let names = try FileManager.default.contentsOfDirectory(atPath: dir.path)
        #expect(names.contains { $0.contains("unreadable") })
    }

    @Test func reportsEngineErrorsWithoutCrashing() {
        let store = GymStore(storage: MemoryStorage(profile))
        store.toggleSet(0, 0, timerRunning: false)
        #expect(store.lastError?.contains("no session in progress") == true)
        store.beginWorkout(routineIds: ["r1"], bodyWeight: nil, freestyleName: "Freestyle")
        store.toggleSet(5, 0, timerRunning: false)
        #expect(store.lastError?.contains("no exercise at 5") == true)
        #expect(store.active?.setsDone == 0)
    }

    @Test func supersetsAndSwaps() throws {
        let store = GymStore(storage: MemoryStorage(profile))
        store.beginWorkout(routineIds: ["r1", "r2"], bodyWeight: nil, freestyleName: "Freestyle")
        store.pair(0, 1)
        #expect(store.active?.units == [[0, 1]])
        let out = try #require(store.toggleSet(0, 0, timerRunning: false))
        #expect(out.cur == 1)
        let swap = try #require(store.swapExercise(0, to: "0032"))
        #expect(swap.needsConfirmation == true)
    }
}
