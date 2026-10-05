import Foundation
import Testing
@testable import OpenGymCore

private let csv = """
Date,Exercise,Category,Weight (kg),Reps
2026-03-02,Flat Barbell Bench Press,Chest,60,5
2026-03-05,Barbell Squat,Legs,80,5
"""

// The engine holds one profile, so these run one at a time (and apart from GymStoreTests).
@Suite(.serialized) @MainActor
struct DataTests {
    @Test func exportResetImportRoundTrip() throws {
        let store = GymStore(storage: MemoryStorage(#"{"restSec": 75, "routines": [{"id": "r1", "name": "Push", "emoji": "dumbbell", "ex": []}]}"#))
        let backup = try store.exportJSON()
        #expect(store.backupInfo(json: backup).routines == 1)
        store.resetEverything()
        #expect(store.routines.isEmpty)
        #expect(store.prefs()?.restSec == 90)
        try store.importBackup(json: backup)
        #expect(store.routines.map(\.name) == ["Push"])
        #expect(store.prefs()?.restSec == 75)
        #expect(throws: DataError.notABackup) { try store.importBackup(json: "[]") }
        #expect(store.routines.map(\.name) == ["Push"])
    }

    @Test func previewsThenImportsACSV() throws {
        let store = GymStore(storage: MemoryStorage())
        let preview = try #require(store.previewImport(text: csv))
        #expect(preview.error == nil)
        #expect(preview.source == "FitNotes")
        #expect(preview.count == 2)
        #expect(store.workouts.isEmpty)
        #expect(store.applyImport()?.added == 2)
        #expect(store.workouts.count == 2)
        #expect(store.previewImport(text: "a,b\n1,2")?.error == "unrecognised")
    }

    @Test func switchesTheUnit() {
        let store = GymStore(storage: MemoryStorage(#"{"exWeights": {"0025": {"w": 100, "d": "2026-01-01"}}}"#))
        store.setUnit("lb", convert: true)
        #expect(store.prefs()?.unit == "lb")
        #expect(store.prefs()?.speedUnit == "mph")
        store.setEffort("rpe")
        #expect(store.prefs()?.effort == "rpe")
    }
}
