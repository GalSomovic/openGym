import Foundation
import OpenGymCore

enum Fmt {
    /// openGym's weight decimals (`wdec`): 1 or 2, display only. Kept in step with the profile
    /// by `sync`, the way openGym's App.jsx pushes it to lib/format.js.
    nonisolated(unsafe) static var weightDecimals = 1

    @MainActor static func sync(_ store: GymStore) { weightDecimals = store.prefs()?.wdec ?? 1 }

    /// openGym's fmtNum: up to `decimals` places (the weight decimals by default), no trailing zeros.
    static func num(_ v: Double, decimals: Int? = nil) -> String {
        v.formatted(.number.precision(.fractionLength(0...(decimals ?? weightDecimals))))
    }

    /// Weekday names in openGym's numbering (0 Sunday … 6 Saturday), in the device language.
    static func weekday(_ day: Int, short: Bool = false) -> String {
        let cal = Calendar.current
        let names = short ? cal.shortStandaloneWeekdaySymbols : cal.standaloneWeekdaySymbols
        return names[(day % 7 + 7) % 7]
    }

    /// The week from the profile's first day (openGym's weekStart: 1 Monday, 0 Sunday).
    static func weekOrder(start: Int) -> [Int] { (0..<7).map { (start + $0) % 7 } }

    static func todayISO(_ date: Date = .now) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    static func exercises(_ n: Int) -> String {
        String(localized: "\(n) exercises")
    }
}
