import Foundation

// History, Home's week and body weight (apple/core/history-actions.js): what the screens show,
// already worded through openGym's i18n, and the steps that change the profile.

/// One workout in the history list (sheets.jsx WorkoutRow).
public struct HistoryRow: Codable, Hashable, Sendable, Identifiable {
    /// The workout's id, or the sync key of one from before ids.
    public var key: String
    public var d: String
    public var name: String
    public var emoji: String?
    public var line: String
    public var prs: Int
    /// "walk", "run" or "cycle" for a GPS activity (activity.js), nil for a strength session.
    public var activity: String?
    public var id: String { key }
}

public struct DetailEntry: Codable, Hashable, Sendable {
    public var idx: Int
    public var id: String
    public var name: String
    public var pr: Bool
    public var sets: String
    public var note: String?
    public var notePin: Bool
}

/// A routine's part of a combined session; a single-routine workout has one untitled section.
public struct DetailSection: Codable, Hashable, Sendable {
    public var title: String?
    public var emoji: String?
    public var summary: String?
    /// Superset units: more than one entry means done back to back.
    public var units: [[DetailEntry]]
}

/// What the workout detail sheet shows (sheets.jsx WorkoutDetail).
public struct WorkoutDetail: Codable, Hashable, Sendable {
    public var key: String
    public var d: String
    public var name: String
    public var line: String
    public var note: String
    public var durationMin: Int
    /// "HH:mm", local.
    public var startTime: String
    public var prs: Int
    public var sections: [DetailSection]
    /// A session is running: the workout cannot be opened in the editor.
    public var busy: Bool
    /// A GPS walk, run or ride: its distance, pace and route.
    public var activity: ActivitySummary?
}

public struct EditOutcome: Codable, Hashable, Sendable {
    public var saved: Bool?
    /// No set is left: offer to delete the workout instead.
    public var empty: Bool?
}

public struct StripDay: Codable, Hashable, Sendable, Identifiable {
    public var iso: String
    public var label: String
    public var num: Int
    /// "done", "plan", "ovr" (rescheduled) or "".
    public var dot: String
    public var today: Bool
    public var id: String { iso }
}

public struct WeekStrip: Codable, Hashable, Sendable {
    public var label: String
    public var days: [StripDay]
}

public struct TodayDone: Codable, Hashable, Sendable {
    public var key: String
    public var name: String
}

public struct TodayInfo: Codable, Hashable, Sendable {
    public var routineIds: [String]
    public var rescheduled: Bool
    public var done: TodayDone?
    /// On a rest day: "Next session: Wednesday, Pull".
    public var next: String?
}

public struct StreakInfo: Codable, Hashable, Sendable {
    public var title: String
    public var line: String
}

public struct DayInfo: Codable, Hashable, Sendable {
    public var title: String
    public var weekly: String
    public var changed: Bool
    public var planned: [String]
    public var missed: Bool
    public var workouts: [String]
}

public struct CalendarDay: Codable, Hashable, Sendable, Identifiable {
    public var iso: String
    public var day: Int
    public var dot: String
    public var today: Bool
    public var workouts: [String]
    public var id: String { iso }
}

public struct CalendarMonth: Codable, Hashable, Sendable {
    public var title: String
    public var summary: String
    public var headers: [String]
    public var blanks: Int
    public var days: [CalendarDay]
}

public struct WeighIn: Codable, Hashable, Sendable {
    public var d: String
    public var w: Double
    public var date: String
}

/// Home's body weight card.
public struct WeightCard: Codable, Hashable, Sendable {
    public var unit: String
    /// The picker's ceiling in this unit.
    public var max: Double
    public var show: Bool
    public var weighIn: Bool
    public var last: WeighIn?
    public var delta: Double?
    public var deltaText: String?
    /// "good" (toward the goal), "bad" or "neutral".
    public var tone: String
    public var goal: Double?
    public var goalText: String?
    public var empty: String
    public var today: String
}

public struct WeightPoint: Codable, Hashable, Sendable {
    public var d: String
    public var w: Double
}

public struct WeighInRow: Codable, Hashable, Sendable {
    public var d: String
    public var w: Double
    public var date: String
    public var text: String
}

public struct WeighInWeek: Codable, Hashable, Sendable, Identifiable {
    public var key: String
    public var title: String
    public var avg: Double
    public var average: String
    public var delta: Double?
    public var deltaText: String?
    public var tone: String
    public var entries: [WeighInRow]
    public var id: String { key }
}

public struct WeighIns: Codable, Hashable, Sendable {
    public var count: Int
    public var title: String
    public var weeks: [WeighInWeek]
}

extension GymStore {
    private static let module = "historyActions"

    /* ------------------------------ workouts ------------------------------ */

    public func historyRows() -> [HistoryRow] { query(Self.module, "historyRows", as: [HistoryRow].self) ?? [] }
    public func historyCount() -> String { query(Self.module, "historyCount", as: String.self) ?? "" }
    public func workoutDetail(_ key: String) -> WorkoutDetail? { query(Self.module, "workoutDetail", [key], as: WorkoutDetail?.self) ?? nil }

    public func setWorkoutNote(_ key: String, _ note: String) {
        perform(Self.module, "setWorkoutNote", [key, note], as: Bool.self)
    }
    /// Throws nothing: a refused move leaves `lastError` set ("Pick a day up to today").
    @discardableResult
    public func moveWorkout(_ key: String, to iso: String, time: String) -> Bool {
        perform(Self.module, "moveWorkout", [key, iso, time], as: Bool.self) ?? false
    }
    @discardableResult
    public func setWorkoutDuration(_ key: String, minutes: Int) -> Bool {
        perform(Self.module, "setDuration", [key, minutes], as: Bool.self) ?? false
    }
    public func deleteWorkout(_ key: String) { perform(Self.module, "deleteWorkout", [key], as: Bool.self) }
    public func workoutText(_ key: String, note: String?) -> String? {
        query(Self.module, "copyText", [key, note ?? NSNull()], as: String?.self) ?? nil
    }
    /// Returns the new routine's id.
    public func saveWorkoutAsRoutine(_ key: String) -> String? { perform(Self.module, "saveAsRoutine", [key], as: String.self) }

    /* ------------------------------ editing a saved workout ------------------------------ */

    @discardableResult
    public func editWorkout(_ key: String) -> Bool { perform(Self.module, "editWorkout", [key], as: Bool.self) ?? false }
    public func saveWorkoutEdit() -> EditOutcome? {
        perform(Self.module, "saveEdit", [Date().timeIntervalSince1970 * 1000], as: EditOutcome.self)
    }
    public func workoutEditUnchanged() -> Bool { query(Self.module, "editUnchanged", as: Bool.self) ?? false }
    public func discardWorkoutEdit() { perform(Self.module, "discardEdit", as: Bool.self) }
    public func deleteEditedWorkout() { perform(Self.module, "deleteEdit", as: Bool.self) }

    /* ------------------------------ the week and the calendar ------------------------------ */

    public func weekStrip(offset: Int, today: String) -> WeekStrip? {
        query(Self.module, "weekStrip", [offset, today], as: WeekStrip.self)
    }
    public func todayInfo(_ today: String) -> TodayInfo? { query(Self.module, "todayInfo", [today], as: TodayInfo.self) }
    public func streak(_ today: String) -> StreakInfo? { query(Self.module, "streak", [today], as: StreakInfo.self) }
    public func dayInfo(_ iso: String, today: String) -> DayInfo? { query(Self.module, "dayInfo", [iso, today], as: DayInfo.self) }
    public func dayChangeText(_ iso: String, _ value: String) -> String {
        query(Self.module, "dayChangeText", [iso, value], as: String.self) ?? ""
    }
    /// `month` is 0–11, as in JavaScript.
    public func calendarMonth(year: Int, month: Int, today: String) -> CalendarMonth? {
        query(Self.module, "calendarMonth", [year, month, today], as: CalendarMonth.self)
    }
    public func sessionName(_ routineIds: [String]) -> String { query(Self.module, "sessionName", [routineIds], as: String.self) ?? "" }

    /* ------------------------------ body weight ------------------------------ */

    public func weightCard() -> WeightCard? { query(Self.module, "weightCard", as: WeightCard.self) }
    public func weightSeries() -> [WeightPoint] { query(Self.module, "weightSeries", as: [WeightPoint].self) ?? [] }
    public func weighIns() -> WeighIns? { query(Self.module, "weighIns", as: WeighIns.self) }
    /// Today's weigh-in (replacing one already logged today). Returns the value saved.
    @discardableResult
    public func logWeight(_ value: Double, on iso: String? = nil) -> Double? {
        perform(Self.module, "logWeight", [value, iso ?? NSNull(), Date().timeIntervalSince1970 * 1000], as: Double.self)
    }
    public func deleteWeighIn(_ iso: String) { perform(Self.module, "deleteWeighIn", [iso], as: Bool.self) }
    /// A target weight, or nil to remove it. Returns the confirmation to show.
    @discardableResult
    public func setWeightGoal(_ value: Double?) -> String? { perform(Self.module, "setGoal", [value ?? NSNull()], as: String.self) }
}

extension ActiveSession {
    /// A saved workout open in the editor (lib/session-edit.js), not a session in progress.
    public var isEditing: Bool { editingWorkoutId != nil }
}
