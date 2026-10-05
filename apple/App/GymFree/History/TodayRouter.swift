import Observation
import OpenGymCore
import SwiftUI

/// Where the Today tab is: the screens pushed on its stack and the one sheet over it. History,
/// the calendar and body weight hang off Today, as they do off openGym's Home.
@MainActor
@Observable
final class TodayRouter {
    enum Route: Hashable {
        case history
        case workout(String)
        case weight
        case exercise(String)
        /// Stats: an exercise's progress curves, the picker that leads to them, structural balance.
        case progress(String)
        case progressPicker
        case balance
    }

    enum Sheet: Identifiable, Hashable {
        case day(String)
        case logPast(LogPastInitial?)
        case calendar
        case weighIn([String])
        case logWeight
        case goal

        var id: String {
            switch self {
            case .day(let iso): "day-\(iso)"
            case .logPast(let i): "log-\(i?.iso ?? "")"
            case .calendar: "calendar"
            case .weighIn: "weighIn"
            case .logWeight: "logWeight"
            case .goal: "goal"
            }
        }
    }

    var path: [Route] = []
    var sheet: Sheet?
    /// Switches tabs (Save as routine opens the plan).
    @ObservationIgnored var openTab: (AppTab) -> Void = { _ in }

    /// A sheet's way to somewhere on the stack: close it, then go.
    func show(_ route: Route) {
        sheet = nil
        if path.last != route { path.append(route) }
    }
}

/// A missed day of the plan: its date and the routines planned for it (sheets.jsx LogPastWorkout).
struct LogPastInitial: Hashable {
    var iso: String
    var routineIds: [String]
}

enum Day {
    /// "2026-10-05" → noon that day, local (openGym reads a day as `iso + 'T12:00:00'`).
    static func date(_ iso: String) -> Date {
        let p = iso.split(separator: "-").compactMap { Int($0) }
        guard p.count == 3 else { return .now }
        return Calendar.current.date(from: DateComponents(year: p[0], month: p[1], day: p[2], hour: 12)) ?? .now
    }

    /// "18:00" on `day`.
    static func time(_ hhmm: String, on day: Date = .now) -> Date {
        let p = hhmm.split(separator: ":").compactMap { Int($0) }
        var c = Calendar.current.dateComponents([.year, .month, .day], from: day)
        c.hour = p.first ?? 18
        c.minute = p.count > 1 ? p[1] : 0
        return Calendar.current.date(from: c) ?? day
    }

    static func hhmm(_ date: Date) -> String {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0)
    }

    static var today: String { Fmt.todayISO() }

    /// The end of today, for date pickers that stop at today.
    static var endOfToday: Date { Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: .now) ?? .now }
}

/// The week strip's and the calendar's dot: done, planned, or rescheduled.
struct DayDot: View {
    let kind: String

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 6, height: 6)
            .opacity(kind.isEmpty ? 0 : 1)
            .accessibilityHidden(true)
    }

    private var color: Color {
        switch kind {
        case "done": .accentColor
        case "ovr": .orange
        case "plan": .secondary
        default: .clear
        }
    }

    /// For VoiceOver, after the date.
    static func label(_ kind: String) -> Text? {
        switch kind {
        case "done": Text("Trained")
        case "ovr": Text("Rescheduled")
        case "plan": Text("Planned")
        default: nil
        }
    }
}
