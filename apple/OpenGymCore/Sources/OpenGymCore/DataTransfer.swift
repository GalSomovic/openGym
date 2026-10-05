import Foundation

/// The General and During a workout settings as openGym reads them (settings.js prefs).
public struct Prefs: Codable, Hashable, Sendable {
    public var unit: String
    public var speedUnit: String
    public var wdec: Int
    public var weekStart: Int
    public var effort: String
    public var startFrom: String
    public var restSec: Double
    public var restPauseSec: Double
    public var timedSetOvertime: Bool
    public var keepAwake: Bool
    public var weighIn: Bool
    public var sound: Bool
    public var vibrate: Bool
}

/// What a picked backup holds (data.js backupInfo).
public struct BackupInfo: Codable, Hashable, Sendable {
    public var ok: Bool
    public var workouts: Int?
    public var routines: Int?
    public var bodyweight: Int?
    public var unit: String?
    public var from: String?
    public var to: String?
}

/// What importing another app's export would do (data.js previewImport).
public struct ImportPreview: Codable, Hashable, Sendable, Identifiable {
    /// "empty", "unrecognised", "unreadable" or "nothing"; the rest is nil then.
    public var error: String?
    /// "workouts" or "bodyweight".
    public var kind: String?
    public var source: String?
    public var from: String?
    public var to: String?
    /// Workouts or weigh-ins in the file; `have` of their days already hold data and are skipped.
    public var count: Int?
    public var have: Int?
    public var fresh: Int?
    public var sets: Int?
    public var matched: Int?
    public var created: Int?
    public var unmatchedNames: [String]?
    public var fileUnit: String?
    public var converted: Bool?
    public var mixedUnits: Bool?
    public var unit: String?
    public var effortSets: Int?
    public var effortKind: String?
    public var effortOn: Bool?

    public var isBodyweight: Bool { kind == "bodyweight" }
    public var id: String { "\(source ?? "")|\(from ?? "")|\(to ?? "")|\(count ?? 0)" }
}

public struct ImportResult: Codable, Hashable, Sendable {
    public var kind: String
    public var added: Int
    public var skipped: Int
}

extension GymStore {
    public func prefs() -> Prefs? { query("settings", "prefs", as: Prefs.self) }

    public func setEffort(_ kind: String) { perform("settings", "setEffort", [kind], as: Prefs.self) }

    /// Switches kg and lb; `convert` walks every stored weight into the new unit.
    public func setUnit(_ unit: String, convert: Bool) {
        perform("data", "setUnit", [unit, convert], as: Bool.self)
    }

    public func backupInfo(json: String) -> BackupInfo {
        query("data", "backupInfo", [json], as: BackupInfo.self) ?? BackupInfo(ok: false)
    }

    /// An openGym backup in place of everything. Throws on a file that is not one.
    public func importBackup(json: String) throws {
        guard backupInfo(json: json).ok else { throw DataError.notABackup }
        guard perform("data", "importBackup", [json], as: Bool.self) == true else { throw DataError.notABackup }
    }

    /// Back to an empty profile, as openGym's Reset everything.
    public func resetEverything() {
        perform("data", "resetEverything", [Date().timeIntervalSince1970 * 1000], as: Bool.self)
    }

    /// Reads a CSV or Health export and holds it for `applyImport`. Changes nothing.
    public func previewImport(text: String) -> ImportPreview? {
        query("data", "previewImport", [text], as: ImportPreview.self)
    }

    @discardableResult
    public func applyImport() -> ImportResult? { perform("data", "applyImport", as: ImportResult.self) }

    public func cancelImport() { _ = query("data", "cancelImport", as: Bool.self) }
}

public enum DataError: Error, Equatable {
    case notABackup
}
