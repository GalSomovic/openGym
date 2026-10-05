import Foundation

// GPS walks, runs and rides (apple/core/activity.js): filed as cardio workouts so History and
// the streak count them, with GymFree's summary on the record.

/// The activity part of a saved workout, already worded in km or miles.
public struct ActivitySummary: Codable, Hashable, Sendable {
    public var kind: String
    public var meters: Double
    public var movingSec: Double
    public var ascent: Double?
    /// A route file was saved with it.
    public var route: Bool
    /// The Apple Health workout it was saved as.
    public var hk: String?
    /// "5.00 km"
    public var distance: String
    /// "6:00 /km"; nil for a distance too short to divide.
    public var pace: String?
    /// "10 km/h"
    public var speed: String
    /// "30 min"
    public var moving: String
    public var imperial: Bool

    public var activityKind: ActivityKind? { ActivityKind(rawValue: kind) }
}

/// A finished activity, as the tracker hands it over.
public struct ActivityRecord: Sendable {
    public var kind: ActivityKind
    public var start: Date
    public var end: Date
    public var movingSec: Double
    public var meters: Double
    public var ascent: Double
    public var hasRoute: Bool

    public init(kind: ActivityKind, start: Date, end: Date, movingSec: Double, meters: Double, ascent: Double = 0, hasRoute: Bool) {
        self.kind = kind; self.start = start; self.end = end; self.movingSec = movingSec
        self.meters = meters; self.ascent = ascent; self.hasRoute = hasRoute
    }
}

extension GymStore {
    private static let activityModule = "activity"

    /// Files the activity in the history. Returns its key (the workout id).
    @discardableResult
    public func logActivity(_ r: ActivityRecord) -> String? {
        let spec: [String: Any] = [
            "kind": r.kind.rawValue,
            "start": r.start.timeIntervalSince1970 * 1000,
            "end": r.end.timeIntervalSince1970 * 1000,
            "movingSec": r.movingSec,
            "meters": r.meters,
            "ascent": r.ascent,
            "route": r.hasRoute,
        ]
        return perform(Self.activityModule, "logActivity", [spec, Date().timeIntervalSince1970 * 1000], as: String.self)
    }

    public func setActivityHealthId(_ key: String, _ uuid: UUID) {
        perform(Self.activityModule, "setActivityHealthId", [key, uuid.uuidString, Date().timeIntervalSince1970 * 1000], as: Bool.self)
    }

    /// Keys of every saved activity, newest first.
    public func activityKeys() -> [String] { query(Self.activityModule, "activityKeys", as: [String].self) ?? [] }

    /// Distances in miles when the profile's speed unit is mph.
    public var motionFormat: MotionFormat { MotionFormat(speedUnit: prefs()?.speedUnit) }
}
