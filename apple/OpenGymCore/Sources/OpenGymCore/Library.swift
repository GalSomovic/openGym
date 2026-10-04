import Foundation

/// One catalogue exercise, as the library lists it (library.js catalogue).
public struct ExerciseBrief: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    /// openGym's English name, lower case ("barbell bench press"), as the catalogue has it.
    public var n: String
    /// Body part ("chest", "upper legs").
    public var bp: String
    public var eq: String?
    /// Target muscle.
    public var tg: String?
    public var sm: [String]
    public var custom: Bool
    public var cardio: Bool

    /// The name as openGym shows it: every word capitalised, like CSS `text-transform: capitalize`.
    public var displayName: String { n.capitalizedWords }
}

public struct ExerciseDetail: Codable, Hashable, Sendable {
    public var id: String
    public var n: String
    public var bp: String
    public var eq: String?
    public var tg: String?
    public var sm: [String]
    public var custom: Bool
    public var cardio: Bool
    /// Step-by-step instructions.
    public var st: [String]
    public var desc: String?
    public var best: Double
    public var fav: Bool
    public var note: String?

    public var displayName: String { n.capitalizedWords }
}

public struct LibraryResult: Codable, Hashable, Sendable {
    public var ids: [String]
    /// Equipment present in what is left, most common first.
    public var equipment: [String]
    /// The equipment filter actually applied (dropped when the search narrowed it away).
    public var eq: String
    /// The active equipment profile's name, when one filters the list.
    public var profile: String?
}

public struct StarterPlan: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var days: Int
    public var weekdays: [Int]
}

public struct RoutineMuscles: Codable, Hashable, Sendable {
    public var load: [String: Double]
    public var worked: [String]
}

/// What the exercise settings sheet shows for a draft (plan.js configInfo).
public struct ConfigInfo: Codable, Hashable, Sendable {
    public var cardio: Bool
    public var mode: String
    public var bw: Bool
    public var perSide: Bool
    public var policy: String
    public var inheritedPolicy: String
    public var policies: [String]
    public var policyNames: [String: String]
    public var policyDesc: String?
    public var step: Double
    public var stepValid: Bool
    public var double: Bool
    public var range: RepRange?
    public var epleyEligible: Bool
    public var maxWarmups: Int
    public var maxBwSets: Int
    public var unit: String
    public var speedUnit: String
    public var restPauseSec: Double
}

public struct RepRange: Codable, Hashable, Sendable {
    public var reps: Double
    public var repsMin: Double
}

/// A routine exercise or settings-sheet draft: openGym's config object, kept whole.
public typealias ExerciseConfig = [String: JSONValue]

extension String {
    /// Upper-cases the first letter of every space-separated word, leaving the rest alone.
    public var capitalizedWords: String {
        split(separator: " ", omittingEmptySubsequences: false)
            .map { word in word.isEmpty ? "" : word.prefix(1).uppercased() + word.dropFirst() }
            .joined(separator: " ")
    }
}

extension Dictionary where Key == String, Value == JSONValue {
    var anyObject: [String: Any] { mapValues(\.any) }
}

/* ------------------------------ library, plan and settings actions ------------------------------ */

extension GymStore {
    public func catalogue() -> [ExerciseBrief] { query("library", "catalogue", as: [ExerciseBrief].self) ?? [] }
    public func bodyParts() -> [String] { query("library", "bodyParts", as: [String].self) ?? [] }

    public func browse(query q: String, bodyPart: String, equipment: String, showAll: Bool) -> LibraryResult? {
        query("library", "browse", [["q": q, "bp": bodyPart, "eq": equipment, "showAll": showAll]], as: LibraryResult.self)
    }

    public func exerciseDetail(_ id: String) -> ExerciseDetail? {
        query("library", "detail", [id], as: ExerciseDetail?.self) ?? nil
    }

    public func bests(_ ids: [String]) -> [String: Double] {
        query("library", "bests", [ids], as: [String: Double].self) ?? [:]
    }

    public func toggleFavourite(_ id: String) { perform("library", "toggleFavourite", [id], as: Bool.self) }
    public func setStandingNote(_ id: String, _ text: String) { perform("library", "setExerciseNote", [id, text], as: Bool.self) }

    /* routines */

    @discardableResult
    public func addRoutine(name: String, emoji: String = "dumbbell") -> String? {
        perform("plan", "addRoutine", [name, emoji], as: String.self)
    }
    public func moveRoutine(_ index: Int, by delta: Int) { perform("plan", "moveRoutine", [index, delta], as: Bool.self) }
    public func deleteRoutine(_ id: String) { perform("plan", "deleteRoutine", [id], as: Bool.self) }
    @discardableResult
    public func copyRoutine(_ id: String, suffix: String) -> String? { perform("plan", "copyRoutine", [id, suffix], as: String.self) }
    public func renameRoutine(_ id: String, _ name: String, fallback: String) {
        perform("plan", "renameRoutine", [id, name, fallback], as: Bool.self)
    }
    public func setRoutineEmoji(_ id: String, _ emoji: String) { perform("plan", "setRoutineEmoji", [id, emoji], as: Bool.self) }
    public func setRoutineProgression(_ id: String, _ policy: String) { perform("plan", "setRoutineProgression", [id, policy], as: Bool.self) }
    public func setRoutineDeload(_ id: String, _ on: Bool) { perform("plan", "setRoutineDeload", [id, on], as: Bool.self) }
    public func routineLines(_ id: String) -> [String] { query("plan", "routineLines", [id], as: [String].self) ?? [] }
    public func routineMuscles(_ id: String) -> RoutineMuscles? { query("plan", "routineMuscles", [id], as: RoutineMuscles.self) }

    /// The raw config objects of a routine's exercises, for the settings sheet.
    public func routineConfigs(_ id: String) -> [ExerciseConfig] {
        guard let all = pick("routines", as: [[String: JSONValue]].self),
              let r = all.first(where: { $0["id"]?.string == id }),
              case .array(let ex)? = r["ex"] else { return [] }
        return ex.compactMap { if case .object(let o) = $0 { o } else { nil } }
    }

    public func addRoutineExercise(_ rid: String, _ exId: String, config: ExerciseConfig? = nil) {
        perform("plan", "addRoutineExercise", [rid, exId, config?.anyObject ?? NSNull()], as: Bool.self)
    }
    @discardableResult
    public func addToRoutine(_ exId: String, routine rid: String?, config: ExerciseConfig?, newName: String) -> String? {
        perform("plan", "addToRoutine", [exId, rid ?? NSNull(), config?.anyObject ?? NSNull(), newName], as: String.self)
    }
    public func updateRoutineExercise(_ rid: String, _ index: Int, config: ExerciseConfig) {
        perform("plan", "updateRoutineExercise", [rid, index, config.anyObject], as: Bool.self)
    }
    public func removeRoutineExercise(_ rid: String, _ index: Int) { perform("plan", "removeRoutineExercise", [rid, index], as: Bool.self) }
    public func moveRoutineExercise(_ rid: String, _ index: Int, _ dir: Int) { perform("plan", "moveRoutineExercise", [rid, index, dir], as: Bool.self) }
    public func reorderRoutineExercise(_ rid: String, from source: Int, toSlot slot: Int) {
        perform("plan", "reorderRoutineExercise", [rid, source, slot], as: Bool.self)
    }
    public func toggleSupersetLink(_ rid: String, _ index: Int) { perform("plan", "toggleSupersetLink", [rid, index], as: Bool.self) }
    public func replacementFor(_ rid: String, _ index: Int, with exId: String) -> ExerciseConfig? {
        query("plan", "replacementFor", [rid, index, exId], as: ExerciseConfig?.self) ?? nil
    }
    public func replaceRoutineExercise(_ rid: String, _ index: Int, with exId: String, config: ExerciseConfig? = nil) {
        perform("plan", "replaceRoutineExercise", [rid, index, exId, config?.anyObject ?? NSNull()], as: Bool.self)
    }

    /* the settings sheet */

    public func configStart(_ exId: String, existing: ExerciseConfig?, routine rid: String?, initial: ExerciseConfig? = nil) -> ExerciseConfig {
        query("plan", "configStart", [exId, existing?.anyObject ?? NSNull(), rid ?? NSNull(), initial?.anyObject ?? NSNull()],
              as: ExerciseConfig.self) ?? [:]
    }
    public func configInfo(_ exId: String, _ draft: ExerciseConfig, routine rid: String?) -> ConfigInfo? {
        query("plan", "configInfo", [exId, draft.anyObject, rid ?? NSNull()], as: ConfigInfo.self)
    }
    public func configWithMode(_ exId: String, _ draft: ExerciseConfig, _ mode: String, routine rid: String?) -> ExerciseConfig {
        query("plan", "configWithMode", [exId, draft.anyObject, mode, rid ?? NSNull()], as: ExerciseConfig.self) ?? draft
    }
    public func configWithPerSide(_ exId: String, _ draft: ExerciseConfig, _ on: Bool, routine rid: String?) -> ExerciseConfig {
        query("plan", "configWithPerSide", [exId, draft.anyObject, on, rid ?? NSNull()], as: ExerciseConfig.self) ?? draft
    }
    public func configWithRule(_ exId: String, _ draft: ExerciseConfig, _ rule: String, routine rid: String?) -> ExerciseConfig {
        query("plan", "configWithRule", [exId, draft.anyObject, rule, rid ?? NSNull()], as: ExerciseConfig.self) ?? draft
    }
    public func configWithIntensifier(_ draft: ExerciseConfig, _ type: String) -> ExerciseConfig {
        query("plan", "configWithIntensifier", [draft.anyObject, type], as: ExerciseConfig.self) ?? draft
    }
    /// nil while the progression step is invalid.
    public func configToSave(_ exId: String, _ draft: ExerciseConfig, routine rid: String?) -> ExerciseConfig? {
        query("plan", "configToSave", [exId, draft.anyObject, rid ?? NSNull()], as: ExerciseConfig?.self) ?? nil
    }

    /* the week */

    public var week: [String: [String]] {
        // A day holds a list of ids; very old profiles stored a single id.
        guard let raw = pick("week", as: [String: JSONValue].self) else { return [:] }
        return raw.mapValues { v in
            switch v {
            case .array(let a): a.compactMap(\.string)
            case .string(let s): [s]
            default: []
            }
        }
    }
    public func assignDay(_ day: Int, _ rid: String?) { perform("plan", "assignDay", [day, rid ?? NSNull()], as: Bool.self) }
    public func addRoutineToDay(_ day: Int, _ rid: String) { perform("plan", "addRoutineToDay", [day, rid], as: Bool.self) }
    public func removeFromDay(_ day: Int, _ rid: String) { perform("plan", "removeFromDay", [day, rid], as: Bool.self) }
    public func setDayOverride(_ iso: String, _ value: String) { perform("plan", "setDayOverride", [iso, value], as: Bool.self) }

    public func starterPlans() -> [StarterPlan] { query("plan", "starterPlans", as: [StarterPlan].self) ?? [] }
    public func starterPlanConflicts(_ id: String) -> Bool { query("plan", "starterPlanConflicts", [id], as: Bool.self) ?? false }
    public func loadStarterPlan(_ id: String) { perform("plan", "loadStarterPlan", [id], as: Bool.self) }
}
