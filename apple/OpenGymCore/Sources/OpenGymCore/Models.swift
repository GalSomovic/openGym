import Foundation

// Read-only snapshots of openGym's profile, decoded from the JSON the engine returns. The
// profile itself lives in the engine (apple/core/actions.js) and is only ever changed through
// its actions, so fields these types do not know about are never lost: Swift never writes a
// decoded copy back. Every field is optional or defaulted, as openGym's own readers treat them.

/// Any JSON value, for the parts of the profile the screens pass through untouched
/// (a progression plan, a target's extra keys).
public enum JSONValue: Codable, Hashable, Sendable {
    case null, bool(Bool), number(Double), string(String), array([JSONValue]), object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let b = try? c.decode(Bool.self) { self = .bool(b) }
        else if let n = try? c.decode(Double.self) { self = .number(n) }
        else if let s = try? c.decode(String.self) { self = .string(s) }
        else if let a = try? c.decode([JSONValue].self) { self = .array(a) }
        else { self = .object(try c.decode([String: JSONValue].self)) }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .null: try c.encodeNil()
        case .bool(let b): try c.encode(b)
        case .number(let n): try c.encode(n)
        case .string(let s): try c.encode(s)
        case .array(let a): try c.encode(a)
        case .object(let o): try c.encode(o)
        }
    }

    public subscript(key: String) -> JSONValue? {
        if case .object(let o) = self { return o[key] }
        return nil
    }
    public var number: Double? { if case .number(let n) = self { return n }; return nil }

    /// As Foundation objects, for passing back into the engine.
    public var any: Any {
        switch self {
        case .null: NSNull()
        case .bool(let b): b
        case .number(let n): n
        case .string(let s): s
        case .array(let a): a.map(\.any)
        case .object(let o): o.mapValues(\.any)
        }
    }
    public var string: String? { if case .string(let s) = self { return s }; return nil }
    public var bool: Bool? { if case .bool(let b) = self { return b }; return nil }
}

/// One limb of a per-side set (openGym issue #60).
public struct SideRow: Codable, Hashable, Sendable {
    public var w: Double?
    public var r: Double?
    public var done: Bool?
    public var rir: Double?
    public var rpe: Double?
    /// A side's own drop-set or rest-pause, logged per limb.
    public var type: String?
    public var drops: [Drop]?
    public var clusters: [Burst]?
}

public struct Drop: Codable, Hashable, Sendable {
    public var w: Double?
    public var r: Double?
}

public struct Burst: Codable, Hashable, Sendable {
    public var r: Double?
    public var restSec: Double?
}

/// A set row, in the session and in history. `w`/`r` for reps, `sec` for a hold, `min` and
/// `speed` for cardio.
public struct SetRow: Codable, Hashable, Sendable {
    public var w: Double?
    public var r: Double?
    public var done: Bool?
    public var rir: Double?
    public var rpe: Double?
    public var sec: Double?
    public var min: Double?
    public var speed: Double?
    public var phase: String?
    public var warmup: Bool?
    public var type: String?
    public var drops: [Drop]?
    public var clusters: [Burst]?
    public var sides: [String: SideRow]?

    public var isDone: Bool { done == true }
    /// workout-model.js phaseForSet: an explicit phase wins over the legacy boolean.
    public var isWarmup: Bool {
        if let phase, !phase.isEmpty {
            let p = phase.trimmingCharacters(in: .whitespaces).lowercased()
            return p == "warmup" || p == "warm-up" || p == "warm_up"
        }
        return warmup == true
    }
    public var isPerSide: Bool { sides?["L"] != nil && sides?["R"] != nil }
    public var isDropSet: Bool { type == "dropset" }
    public var isRestPause: Bool { type == "restpause" }
}

/// What a routine asks for of one exercise (and, on a session entry, today's prescription).
public struct ExerciseTarget: Codable, Hashable, Sendable {
    public var sets: Double?
    public var reps: Double?
    public var repsMin: Double?
    public var weight: Double?
    public var sec: Double?
    public var min: Double?
    public var speed: Double?
    public var mode: String?
    public var side: Bool?
    public var restSec: Double?
}

public struct SessionEntry: Codable, Hashable, Sendable, Identifiable {
    /// The exercise id. Not unique within a session (the same exercise can appear twice), so
    /// screens identify an entry by its index.
    public var id: String
    public var sets: [SetRow]
    public var target: ExerciseTarget?
    public var planned: ExerciseTarget?
    public var plan: JSONValue?
    public var rid: String?
    public var sg: String?
    public var noProg: Bool?
    public var carried: Bool?
    public var note: String?
    public var notePin: Bool?
    public var topW: Double?

    public var isFinished: Bool { !sets.isEmpty && sets.allSatisfy(\.isDone) }
}

public struct Backfill: Codable, Hashable, Sendable {
    public var durationMin: Double?
    public var replaceId: String?
}

/// The running session (`S.active`), with the counts the header shows.
public struct ActiveSession: Codable, Hashable, Sendable {
    public var id: String
    public var d: String
    public var start: Double
    public var routineIds: [String]?
    public var name: String?
    public var bw: Double?
    public var cur: Int
    public var entries: [SessionEntry]
    public var workoutView: String?
    public var backfill: Backfill?
    public var note: String?
    public var customName: Bool?
    public var editingWorkoutId: String?
    public var setsDone: Int
    public var setsTotal: Int
    /// Superset groups as entry indexes, in order: `[[0, 1], [2]]`.
    public var units: [[Int]]

    public var startDate: Date { Date(timeIntervalSince1970: start / 1000) }
    public var isBackfill: Bool { backfill != nil }
}

public struct RoutineExercise: Codable, Hashable, Sendable {
    public var id: String
    public var sets: Double?
    public var reps: Double?
    public var repsMin: Double?
    public var weight: Double?
    public var sec: Double?
    public var mode: String?
    public var note: String?
    /// Superset group: neighbours with the same value are done back to back.
    public var sg: String?
}

public struct Routine: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var emoji: String?
    public var ex: [RoutineExercise]
    /// The routine's progression rule ('off', 'linear', 'greyskull', 'double'); absent is linear.
    public var prog: String?
    public var excludeFromProgression: Bool?
}

public struct WorkoutEntry: Codable, Hashable, Sendable {
    public var id: String
    public var sets: [SetRow]
    public var topW: Double?
    public var rid: String?
    public var sg: String?
    public var note: String?
}

/// A finished workout in `S.workouts`.
public struct Workout: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var d: String
    public var start: Double?
    public var end: Double?
    public var name: String?
    public var bw: Double?
    public var routineIds: [String]?
    public var entries: [WorkoutEntry]
    public var prs: [String]?
    public var vol: Double?
    public var note: String?

    public var durationSeconds: Double? {
        guard let start, let end, end > start else { return nil }
        return (end - start) / 1000
    }
}

/* ------------------------------ action results ------------------------------ */

public struct RestRequest: Codable, Hashable, Sendable {
    public var sec: Double
    public var forIdx: Int
}

/// What ticking a set asks of the device (actions.js toggleSet).
public struct ToggleOutcome: Codable, Hashable, Sendable {
    public var checked: Bool
    public var beep: Bool
    /// "cardio" or "hold": a finished cardio or timed exercise is confirmed with a toast.
    public var toast: String?
    /// The last set of the session: offer to finish.
    public var complete: Bool
    public var stopRest: Bool
    public var rest: RestRequest?
    public var cur: Int
}

public struct FinishCheck: Codable, Hashable, Sendable {
    public var done: Int
    public var total: Int
}

/// A heavier estimated 1RM without a heavier top set (onerm.js is1RMRecord): `est` from
/// `w` × `r`, against the best estimate before it.
public struct OneRepMaxRecord: Codable, Hashable, Sendable {
    public var id: String
    public var est: Double
    public var w: Double?
    public var r: Double?
    public var prev: Double?
}

public struct FinishSummary: Codable, Hashable, Sendable {
    public var workout: Workout
    public var prs: [String]
    public var e1prs: [OneRepMaxRecord]
}

public struct SwapResult: Codable, Hashable, Sendable {
    public var inserted: Bool?
    public var index: Int?
    public var needsConfirmation: Bool?
    public var grouped: Bool?
}
