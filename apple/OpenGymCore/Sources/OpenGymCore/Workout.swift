import Foundation

/// A set-row column (Workout.jsx col1/col2/col3): the field it edits and its heading.
public struct EntryColumn: Codable, Hashable, Sendable {
    /// "w", "r", "sec", "min", "speed", or the effort field "rir"/"rpe".
    public var f: String
    public var hd: String
    public var step: Double?
    public var dec: Bool?
    /// Effort columns: "rir" or "rpe". They open a picker instead of a stepper.
    public var eff: String?
    /// Cardio speed: shown and typed in the profile's speed unit.
    public var speed: Bool?
}

public struct EntryRowInfo: Codable, Hashable, Sendable {
    public var warm: Bool
    public var firstWarmup: Bool
    public var sepBefore: Bool
    /// The number shown: counted within warm-ups and work sets separately.
    public var num: Int
    public var label: String
    /// A per-side work set, logged as an L and an R row.
    public var side: Bool
    public var canDrop: Bool
    public var canBurst: Bool
    public var effortColor: String?
    public var speedShown: Double?
}

public struct PlateLine: Codable, Hashable, Sendable {
    public var text: String
    public var short: String?
    public var moves: String
}

public struct Guidance: Codable, Hashable, Sendable {
    public var label: String
    public var why: String
    /// "up", "deload", or another kind of decision.
    public var kind: String?
}

/// Everything one exercise block shows (workout.js entryView), worded in the current language.
public struct EntryView: Codable, Hashable, Sendable {
    public var mode: String
    public var cardio: Bool
    public var timed: Bool
    public var bw: Bool
    public var perSide: Bool
    public var loadStep: Double
    public var unit: String
    public var speedUnit: String
    public var cols: [EntryColumn?]
    public var best: Double
    public var bestText: String?
    public var routineNote: String?
    public var standingNote: String?
    public var pinnedNote: String?
    public var note: String?
    public var planLine: String?
    public var refText: String?
    public var refBest: Bool
    public var refAction: String
    public var lastDate: String?
    public var guidance: Guidance?
    public var noProg: Bool
    public var routineKeepsOut: Bool
    public var plateSummary: String
    public var plateLines: [String: PlateLine]
    public var rows: [EntryRowInfo]
}

public struct ProgressionStart: Codable, Hashable, Sendable {
    public var config: ExerciseConfig
    public var routineId: String?
}

extension GymStore {
    public func entryView(_ idx: Int) -> EntryView? { query("workout", "entryView", [idx], as: EntryView.self) }
    public func toggleLogRef() { perform("workout", "toggleLogRef", as: String.self) }
    public func bump(_ idx: Int, _ set: Int, _ field: String, _ dir: Int, side: String? = nil) {
        perform("workout", "bump", [idx, set, field, dir, side ?? NSNull()], as: Bool.self)
    }
    /// A typed value; nil clears an optional field. Speed is in the unit on screen.
    public func setTyped(_ idx: Int, _ set: Int, _ field: String, _ value: Double?) {
        perform("workout", "setTyped", [idx, set, field, value ?? NSNull()], as: Bool.self)
    }
    public func setSideValue(_ idx: Int, _ set: Int, _ side: String, _ field: String, _ value: Double?) {
        perform("workout", "setSideValue", [idx, set, side, field, value ?? NSNull()], as: Bool.self)
    }
    public func addDrop(_ idx: Int, _ set: Int) { perform("workout", "addDrop", [idx, set], as: Bool.self) }
    public func addBurst(_ idx: Int, _ set: Int) { perform("workout", "addBurst", [idx, set], as: Bool.self) }
    public func removeDrop(_ idx: Int, _ set: Int, _ drop: Int) { perform("workout", "removeDrop", [idx, set, drop], as: Bool.self) }
    public func removeBurst(_ idx: Int, _ set: Int, _ burst: Int) { perform("workout", "removeBurst", [idx, set, burst], as: Bool.self) }
    public func setDrop(_ idx: Int, _ set: Int, _ drop: Int, _ field: String, _ value: Double, side: String? = nil) {
        perform("workout", "setDrop", [idx, set, drop, field, value, side ?? NSNull()], as: Bool.self)
    }
    public func bumpDrop(_ idx: Int, _ set: Int, _ drop: Int, _ field: String, _ dir: Int, side: String? = nil) {
        perform("workout", "bumpDrop", [idx, set, drop, field, dir, side ?? NSNull()], as: Bool.self)
    }
    public func setBurst(_ idx: Int, _ set: Int, _ burst: Int, _ reps: Double, side: String? = nil) {
        perform("workout", "setBurst", [idx, set, burst, reps, side ?? NSNull()], as: Bool.self)
    }
    public func progressionStart(_ idx: Int) -> ProgressionStart? {
        query("workout", "progressionStart", [idx], as: ProgressionStart.self)
    }
    public func applyProgressionSettings(_ idx: Int, _ config: ExerciseConfig) {
        perform("workout", "applyProgressionSettings", [idx, config.anyObject], as: Bool.self)
    }
    public func addExerciseSeed(_ exId: String) -> ExerciseConfig {
        query("actions", "addExerciseSeed", [exId], as: ExerciseConfig.self) ?? [:]
    }
    public func addExercise(_ exId: String, config: ExerciseConfig?) -> Int? {
        addExercise(exId, config: config?.anyObject)
    }
}

/// One set in guided mode (workout.js guide).
public struct GuideStep: Codable, Hashable, Sendable {
    public var idx: Int
    public var set: Int
    public var side: String?
    /// In the exercise (or superset) marked current; otherwise guided mode moves there.
    public var current: Bool
    public var exerciseId: String
    public var mode: String
    public var warm: Bool
    public var timed: Bool
    public var cardio: Bool
    public var bw: Bool
    public var num: Int
    public var count: Int
    public var label: String
    public var w: Double?
    public var r: Double?
    public var sec: Double?
    public var min: Double?
    public var speed: Double?
    public var unitNum: Int?
    public var unitCount: Int?
    public var superset: Bool?
    public var restSec: Double?
}

public struct Guide: Codable, Hashable, Sendable {
    public var done: Bool
    public var step: GuideStep?
    public var next: GuideStep?
    public var unit: String
    public var speedUnit: String
}

extension GymStore {
    public func guide() -> Guide? { query("workout", "guide", as: Guide.self) }
}
