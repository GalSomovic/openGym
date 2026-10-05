import Foundation

// Stats (apple/core/stats.js): openGym's Stats view, activity heatmap, effort card, exercise
// progress and history curves, the 1RM calculator and structural balance, already computed and
// worded by the engine. Swift only draws them.

/// One value of a segmented choice: `value` is what goes back to the engine.
public struct StatsOption: Codable, Hashable, Sendable {
    public var value: JSONValue
    public var label: String
}

/// Stats.jsx's tiles and recent workouts.
public struct StatsOverview: Codable, Hashable, Sendable {
    public var workouts: Int
    public var month: Int
    public var streak: Int
    /// The body weight change over 30 days ("-1.5 kg"), or "—".
    public var weight: String
    /// "neutral" (no change), "plain" (no goal), "good" (toward the goal) or "bad".
    public var tone: String
    public var recent: [HistoryRow]
    public var all: String
    public var hasEffort: Bool
    public var heatmapMetric: String
    public var empty: String
}

/// An exercise in the progress picker, with its latest figure.
public struct ProgressExercise: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var value: String?
}

/// A point on a curve: `t` the session's start (ms), `d` its day.
public struct ChartPoint: Codable, Hashable, Sendable {
    public var t: Double?
    public var d: String?
    public var y: Double
    /// The dot's fill, 0–1: how close to failure the session ran (nil when unrated).
    public var m: Double?
    public var note: String?

    public init(t: Double?, d: String?, y: Double, m: Double? = nil, note: String? = nil) {
        self.t = t; self.d = d; self.y = y; self.m = m; self.note = note
    }

    public var date: Date {
        if let t { return Date(timeIntervalSince1970: t / 1000) }
        // A day is read as noon local, as openGym does (`iso + 'T12:00:00'`).
        let p = (d ?? "").split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return .now }
        return Calendar.current.date(from: DateComponents(year: p[0], month: p[1], day: p[2], hour: 12)) ?? .now
    }
}

public struct ProgressCaptions: Codable, Hashable, Sendable {
    public var top: String
    public var e1rm: String
    public var effort: String
}

public struct ProgressBest: Codable, Hashable, Sendable {
    public var top: String
    public var e1rm: String?
}

public struct ProgressSession: Codable, Hashable, Sendable {
    public var d: String
    public var date: String
    public var sets: String
}

public struct BestSet: Codable, Hashable, Sendable {
    public var d: String
    public var date: String
    public var text: String
}

/// Stats.jsx's Exercise progress card for one exercise.
public struct ExerciseProgress: Codable, Hashable, Sendable {
    public var id: String
    public var name: String
    public var mode: String
    public var unit: String
    /// "RIR" or "RPE".
    public var scale: String
    /// RIR reads upside down: fewer reps left is harder, drawn higher.
    public var invertEffort: Bool
    /// "top", "e1rm", "effort": the curves this exercise has.
    public var metrics: [StatsOption]
    public var top: [ChartPoint]
    public var e1rm: [ChartPoint]
    public var effort: [ChartPoint]
    public var captions: ProgressCaptions
    public var best: ProgressBest
    public var bestLabel: String
    public var e1rmNote: String?
    public var effortNote: String?
    public var recent: [ProgressSession]
    public var bestSet: BestSet?
    public var sessions: Int
}

public struct HistorySheetSession: Codable, Hashable, Sendable, Identifiable {
    public var key: String
    public var date: String
    public var pr: Bool
    public var sets: String
    public var tail: String?
    public var value: String?
    public var id: String { key }
}

/// sheets.jsx ExerciseHistory: the curve and the last sessions of one exercise.
public struct ExerciseHistorySheetData: Codable, Hashable, Sendable {
    public var name: String
    public var total: Int
    public var subtitle: String
    public var empty: String
    public var unit: String
    public var e1rmUnit: String
    public var points: [ChartPoint]
    public var e1rm: [ChartPoint]
    public var bestLabel: String
    public var best: String
    public var e1rmBest: String?
    public var sessionsTitle: String
    public var sessions: [HistorySheetSession]
}

public struct OneRMFromLog: Codable, Hashable, Sendable {
    public var label: String
    public var value: String
    public var line: String
}

public struct RepMax: Codable, Hashable, Sendable, Identifiable {
    public var reps: Int
    public var w: Double
    public var text: String
    public var pct: Int
    public var id: Int { reps }
}

/// sheets.jsx OneRM: the estimate from the log and the calculator.
public struct OneRMCalc: Codable, Hashable, Sendable {
    public var available: Bool
    public var unit: String
    public var w: Double
    public var r: Double
    public var step: Double
    public var title: String
    public var fromLog: OneRMFromLog?
    public var weightLabel: String
    public var repsLabel: String
    public var estimateLabel: String
    public var estimate: Double?
    public var estimateText: String
    public var note: String
    /// The estimate read back as the load for 1–12 reps.
    public var table: [RepMax]
}

public struct HeatCell: Codable, Hashable, Sendable, Identifiable {
    public var iso: String
    /// 0 (rest) to 4 (the top quarter of the chosen metric).
    public var level: Int
    public var n: Int
    public var today: Bool
    public var future: Bool
    public var tip: String?
    public var id: String { iso }
}

public struct HeatWeek: Codable, Hashable, Sendable {
    public var month: String
    public var days: [HeatCell]
}

/// Heatmap.jsx: 53 weeks from the profile's first weekday.
public struct Heatmap: Codable, Hashable, Sendable {
    public var metric: String
    public var title: String
    public var options: [StatsOption]
    public var dayLabels: [String]
    public var weeks: [HeatWeek]
    public var less: String
    public var more: String
}

public struct EffortWeek: Codable, Hashable, Sendable {
    public var t: Double
    public var y: Double
    public var note: String
}

public struct EffortBin: Codable, Hashable, Sendable {
    public var label: String
    public var n: Int
    public var frac: Double
    public var hard: Bool
    public var value: String
}

/// Stats.jsx EffortCard for one window.
public struct EffortCardData: Codable, Hashable, Sendable {
    public var title: String
    public var subtitle: String
    public var windows: [StatsOption]
    public var scale: String
    public var invert: Bool
    public var rated: Int
    public var empty: String
    public var average: String
    public var averageLabel: String
    public var hard: String
    public var hardLabel: String
    public var coverage: String
    public var off: String?
    public var weeksTitle: String
    public var weeks: [EffortWeek]
    public var binsTitle: String
    public var bins: [EffortBin]
    public var footer: String
}

public struct BalanceTemplate: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var label: String
}

public struct BalanceRow: Codable, Hashable, Sendable, Identifiable {
    public var role: String
    public var label: String
    public var exercise: String?
    public var exerciseId: String?
    public var custom: Bool
    /// "balanced", "borderline", "weak" or "no-data".
    public var status: String
    public var statusLabel: String
    public var value: String
    public var needsBodyweight: Bool
    public var needsAnchor: Bool
    public var id: String { role }
}

/// StructuralBalance.jsx: the chosen ratio table, each lift against its target.
public struct BalanceData: Codable, Hashable, Sendable {
    public var title: String
    public var subtitle: String
    public var template: String
    public var templates: [BalanceTemplate]
    public var rows: [BalanceRow]
}

extension GymStore {
    private static let stats = "stats"
    private var nowMs: Double { Date().timeIntervalSince1970 * 1000 }

    public func statsOverview(today: String) -> StatsOverview? {
        query(Self.stats, "overview", [nowMs, today], as: StatsOverview.self)
    }
    public func progressExercises(_ query: String = "") -> [ProgressExercise] {
        self.query(Self.stats, "progressExercises", [query], as: [ProgressExercise].self) ?? []
    }
    public func exerciseProgress(_ id: String) -> ExerciseProgress? {
        query(Self.stats, "exerciseProgress", [id], as: ExerciseProgress.self)
    }
    public func exerciseHistorySheet(_ id: String) -> ExerciseHistorySheetData? {
        query(Self.stats, "historySheet", [id], as: ExerciseHistorySheetData.self)
    }
    /// The calculator for `weight` × `reps`, or opening on the best logged set (nil, nil).
    public func oneRM(_ id: String, weight: Double? = nil, reps: Double? = nil) -> OneRMCalc? {
        query(Self.stats, "oneRM", [id, weight ?? NSNull(), reps ?? NSNull()], as: OneRMCalc.self)
    }
    /// `metric` "time" or "vol"; nil reads the profile's choice.
    public func heatmap(_ metric: String? = nil) -> Heatmap? {
        query(Self.stats, "heatmap", [metric ?? NSNull(), nowMs], as: Heatmap.self)
    }
    public func setHeatmapMetric(_ metric: String) { perform(Self.stats, "setHeatmapMetric", [metric], as: Bool.self) }
    /// `days` 30, 90, 365, or 0 for everything.
    public func effortCard(days: Int) -> EffortCardData? {
        query(Self.stats, "effortCard", [days], as: EffortCardData.self)
    }
    public func structuralBalance() -> BalanceData? { query(Self.stats, "balance", as: BalanceData.self) }
    public func setBalanceTemplate(_ id: String) { perform(Self.stats, "setBalanceTemplate", [id], as: Bool.self) }
    /// Points a lift at another exercise, or back to the table's own (nil).
    public func setBalanceExercise(_ role: String, _ exerciseId: String?) {
        perform(Self.stats, "setBalanceExercise", [role, exerciseId ?? NSNull(), nowMs], as: Bool.self)
    }
}
