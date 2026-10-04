import Foundation
import Observation

/// Where the profile is kept between launches: openGym's state JSON, as one file.
public protocol StateStorage: Sendable {
    func read() throws -> String?
    func write(_ json: String) throws
}

/// The profile in Application Support, written atomically so a crash mid-save keeps the last
/// good copy.
public struct FileStateStorage: StateStorage {
    public let url: URL

    public init(url: URL) { self.url = url }

    public static func standard() throws -> FileStateStorage {
        let dir = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                              appropriateFor: nil, create: true)
        return FileStateStorage(url: dir.appendingPathComponent("gym_state_v1.json"))
    }

    public func read() throws -> String? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try String(contentsOf: url, encoding: .utf8)
    }

    public func write(_ json: String) throws {
        try Data(json.utf8).write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}

/// The app's single source of truth. It owns no training logic: every change is one of
/// openGym's actions run in the engine (apple/core/actions.js), after which the snapshots the
/// screens read are refreshed and the profile is saved.
@MainActor
@Observable
public final class GymStore {
    public private(set) var active: ActiveSession?
    public private(set) var routines: [Routine] = []
    /// Bumped on every change, for screens that read the profile through `pick`.
    public private(set) var revision = 0
    public private(set) var lastError: String?

    @ObservationIgnored private let engine: Engine
    @ObservationIgnored private let storage: StateStorage
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private let saveDelay: Duration

    public init(storage: StateStorage, engine: Engine = .shared, saveDelay: Duration = .milliseconds(400)) {
        self.storage = storage
        self.engine = engine
        self.saveDelay = saveDelay
        do {
            let saved = try storage.read()
            _ = try engine.call("actions", "load", [saved ?? NSNull()], as: Bool.self)
        } catch {
            // An unreadable file is kept aside rather than overwritten by an empty profile.
            lastError = "\(error)"
            _ = try? engine.call("actions", "load", [NSNull()], as: Bool.self)
            if let file = storage as? FileStateStorage {
                let aside = file.url.deletingPathExtension().appendingPathExtension("unreadable-\(Int(Date().timeIntervalSince1970)).json")
                try? FileManager.default.moveItem(at: file.url, to: aside)
            }
        }
        refresh()
    }

    /* ------------------------------ reading ------------------------------ */

    /// Top-level profile fields, decoded: `store.pick("restSec", as: Double.self)`.
    public func pick<T: Decodable>(_ key: String, as type: T.Type = T.self) -> T? {
        guard let dict = try? engine.call("actions", "pick", [[key]], as: [String: JSONValue].self),
              let raw = dict[key], let data = try? JSONEncoder().encode(raw) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    public var workouts: [Workout] { pick("workouts", as: [Workout].self) ?? [] }

    public func todayRoutineIds(on iso: String? = nil) -> [String] {
        (try? engine.call("actions", "todayRoutineIds", [iso ?? NSNull()], as: [String].self)) ?? []
    }

    public func exportJSON() throws -> String {
        try engine.callString("actions", "exportState")
    }

    /* ------------------------------ writing ------------------------------ */

    /// Writes settings or other top-level values: `store.patch(["restSec": 120])`.
    public func patch(_ values: [String: Any]) {
        run { try $0.call("actions", "patch", [values], as: Bool.self) }
    }

    /// Replaces the whole profile (an openGym backup being restored).
    public func replaceProfile(json: String) throws {
        _ = try engine.call("actions", "load", [json], as: Bool.self)
        changed()
    }

    public func beginWorkout(routineIds: [String], bodyWeight: Double?, freestyleName: String) {
        run { try $0.call("actions", "beginWorkout", [routineIds, bodyWeight ?? NSNull(), freestyleName], as: ActiveSession.self) }
    }

    public func beginBackfill(iso: String, time: String, durationMin: Int, routineIds: [String],
                              replaceId: String?, freestyleName: String) {
        let spec: [String: Any] = ["iso": iso, "time": time, "durationMin": durationMin,
                                   "routineIds": routineIds, "replaceId": replaceId ?? NSNull()]
        run { try $0.call("actions", "beginBackfill", [spec, freestyleName], as: ActiveSession.self) }
    }

    public func workouts(on iso: String) -> [Workout] {
        (try? engine.call("actions", "workoutsOnDay", [iso], as: [Workout].self)) ?? []
    }

    public func discardWorkout() { run { try $0.call("actions", "discardWorkout", as: Bool.self) } }

    @discardableResult
    public func toggleSet(_ entry: Int, _ set: Int, side: String? = nil, timerRunning: Bool) -> ToggleOutcome? {
        run { try $0.call("actions", "toggleSet", [entry, set, side ?? NSNull(), ["timerRunning": timerRunning]], as: ToggleOutcome.self) }
    }

    /// A timed hold ended. Not abandoned, it ticks the set and returns what follows.
    @discardableResult
    public func recordHold(_ entry: Int, _ set: Int, elapsed: Double, abandoned: Bool, plan: Double,
                           timerRunning: Bool, quiet: Bool) -> ToggleOutcome? {
        let opts: [String: Any] = ["abandoned": abandoned, "plan": plan, "timerRunning": timerRunning, "quiet": quiet]
        let args: [Any] = [entry, set, elapsed, opts]
        return run { engine in
            try engine.call("actions", "recordHold", args, as: JSONValue.self)
        }.flatMap { value in
            guard value["checked"] != nil, let data = try? JSONEncoder().encode(value) else { return nil }
            return try? JSONDecoder().decode(ToggleOutcome.self, from: data)
        }
    }

    /// Sets or clears (`nil`) one field of a set: "w", "r", "rir", "rpe", "sec", "min", "speed".
    public func setField(_ entry: Int, _ set: Int, _ field: String, _ value: Double?) {
        run { try $0.call("actions", "setField", [entry, set, field, value ?? NSNull()], as: JSONValue.self) }
    }

    public func addSet(_ entry: Int) { run { try $0.call("actions", "addSet", [entry], as: JSONValue.self) } }
    public func removeSet(_ entry: Int) { run { try $0.call("actions", "removeSet", [entry], as: JSONValue.self) } }
    public func addWarmup(_ entry: Int) { run { try $0.call("actions", "addWarmup", [entry], as: JSONValue.self) } }
    public func removeSet(_ entry: Int, at set: Int) { run { try $0.call("actions", "removeSetAt", [entry, set], as: JSONValue.self) } }

    public func navigate(_ direction: Int) { run { try $0.call("actions", "navigateUnit", [direction], as: Int.self) } }
    public func setCurrent(_ entry: Int) { run { try $0.call("actions", "setCurrent", [entry], as: Int.self) } }
    public func setWorkoutView(_ view: String) { run { try $0.call("actions", "setWorkoutView", [view], as: Bool.self) } }
    public func renameWorkout(_ name: String) { run { try $0.call("actions", "renameWorkout", [name], as: Bool.self) } }
    public func setSessionNote(_ note: String) { run { try $0.call("actions", "setSessionNote", [note], as: Bool.self) } }
    public func setExerciseNote(_ entry: Int, _ note: String, pinned: Bool) {
        run { try $0.call("actions", "setExerciseNote", [entry, note, pinned], as: JSONValue.self) }
    }

    public func removeExercise(_ entry: Int) { run { try $0.call("actions", "removeExercise", [entry], as: Bool.self) } }
    public func canMove(_ entry: Int, _ direction: Int) -> Bool {
        (try? engine.call("actions", "canMoveUnit", [entry, direction], as: Bool.self)) ?? false
    }
    /// Returns the new order as old indexes, so a running rest can follow its exercise.
    @discardableResult
    public func move(_ entry: Int, _ direction: Int) -> [Int]? {
        run { try $0.call("actions", "moveUnit", [entry, direction], as: [Int]?.self) } ?? nil
    }
    public func pair(_ first: Int, _ second: Int) { run { try $0.call("actions", "pair", [first, second], as: Bool.self) } }
    public func unpair(_ entry: Int) { run { try $0.call("actions", "unpair", [entry], as: Bool.self) } }
    public func setExerciseNoProgression(_ entry: Int, _ on: Bool) {
        run { try $0.call("actions", "setExerciseNoProg", [entry, on], as: Bool.self) }
    }
    public func toggleSessionNoProgression() { run { try $0.call("actions", "toggleSessionNoProg", as: Bool.self) } }

    /// Adds an exercise after the current one. `config` nil uses the quick-add default.
    @discardableResult
    public func addExercise(_ exerciseId: String, config: [String: Any]? = nil) -> Int? {
        run { try $0.call("actions", "addExercise", [exerciseId, config ?? NSNull()], as: Int.self) }
    }

    @discardableResult
    public func swapExercise(_ entry: Int, to exerciseId: String, config: [String: Any]? = nil,
                             loggedConfirmed: Bool = false, groupDisposition: String? = nil) -> SwapResult? {
        var opts: [String: Any] = ["loggedConfirmed": loggedConfirmed]
        if let groupDisposition { opts["groupDisposition"] = groupDisposition }
        return run { try $0.call("actions", "swapExercise", [entry, exerciseId, config ?? NSNull(), opts], as: SwapResult?.self) } ?? nil
    }

    public func addRoutineToSession(_ routineId: String) {
        run { try $0.call("actions", "addRoutineToSession", [routineId], as: Bool.self) }
    }

    public func markAllDone() { run { try $0.call("actions", "markAllDone", as: Bool.self) } }

    public func finishCheck() -> FinishCheck? {
        try? engine.call("actions", "finishCheck", as: FinishCheck?.self)
    }

    @discardableResult
    public func finishWorkout() -> FinishSummary? {
        run { try $0.call("actions", "finishWorkout", [Date().timeIntervalSince1970 * 1000], as: FinishSummary?.self) } ?? nil
    }

    /* ------------------------------ plumbing ------------------------------ */

    /// Runs an action that changes the profile (`OG.<module>.<function>`), then refreshes and
    /// saves. Returns nil and records `lastError` if the engine refuses.
    @discardableResult
    public func perform<T: Decodable>(_ module: String, _ function: String, _ args: [Any] = [],
                                      as type: T.Type = T.self) -> T? {
        run { try $0.call(module, function, args, as: T.self) }
    }

    /// Reads from the engine without changing anything.
    public func query<T: Decodable>(_ module: String, _ function: String, _ args: [Any] = [],
                                    as type: T.Type = T.self) -> T? {
        do { return try engine.call(module, function, args, as: T.self) }
        catch { lastError = "\(error)"; return nil }
    }

    @discardableResult
    private func run<T>(_ body: (Engine) throws -> T) -> T? {
        do {
            let value = try body(engine)
            lastError = nil
            changed()
            return value
        } catch {
            lastError = "\(error)"
            return nil
        }
    }

    private func changed() {
        refresh()
        revision &+= 1
        scheduleSave()
    }

    private func refresh() {
        active = try? engine.call("actions", "active", as: ActiveSession?.self)
        routines = pick("routines", as: [Routine].self) ?? []
    }

    private func scheduleSave() {
        saveTask?.cancel()
        let delay = saveDelay
        saveTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }

    /// Writes the profile now: on going to the background, and at the end of a debounce.
    public func saveNow() {
        saveTask?.cancel()
        saveTask = nil
        do { try storage.write(try engine.callString("actions", "exportState")) }
        catch { lastError = "\(error)" }
    }
}
