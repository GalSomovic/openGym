import Foundation

enum Fmt {
    /// openGym's fmtNum: up to `decimals` places, no trailing zeros.
    static func num(_ v: Double, decimals: Int = 1) -> String {
        v.formatted(.number.precision(.fractionLength(0...decimals)))
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
