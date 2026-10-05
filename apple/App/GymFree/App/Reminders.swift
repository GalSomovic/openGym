import OpenGymCore
import SwiftUI
import UserNotifications

/// Workout-day reminders: one local notification per upcoming planned day (apple/core/reminders.js),
/// rescheduled whenever the plan or the setting changes and when the app comes back.
@MainActor
enum Reminders {
    private struct Upcoming: Decodable { var iso: String; var at: Double; var routines: [String]; var count: Int }
    private static let prefix = "gf.reminder."

    /// Turns reminders on or off; asks for permission only here, from the user's tap.
    static func setOn(_ on: Bool, store: GymStore) async -> Bool {
        if on {
            let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
            guard granted else { return false }
        }
        store.perform("reminders", "setReminder", [["on": on]], as: JSONValue.self)
        await sync(store: store)
        return true
    }

    static func setTime(_ date: Date, store: GymStore) async {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        store.perform("reminders", "setReminder", [["time": String(format: "%02d:%02d", c.hour ?? 8, c.minute ?? 0)]], as: JSONValue.self)
        await sync(store: store)
    }

    /// Replaces the scheduled reminders with the current plan's. Never prompts.
    static func sync(store: GymStore) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
        let list = store.query("reminders", "upcoming", [Date().timeIntervalSince1970 * 1000], as: [Upcoming].self) ?? []
        for item in list {
            let content = UNMutableNotificationContent()
            content.title = String(localized: "Workout day")
            let label = item.count <= 2 ? item.routines.joined(separator: " + ") : String(localized: "\(item.count) routines")
            content.body = String(localized: "\(label) is on the plan today. Let's go!")
            content.sound = .default
            let when = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute],
                                                       from: Date(timeIntervalSince1970: item.at / 1000))
            let request = UNNotificationRequest(identifier: prefix + item.iso, content: content,
                                                trigger: UNCalendarNotificationTrigger(dateMatching: when, repeats: false))
            try? await center.add(request)
        }
    }
}

/// Settings section: a switch and a time.
struct ReminderSettingsSection: View {
    @Environment(GymStore.self) private var store
    @State private var denied = false

    private struct Setting: Decodable { var on: Bool; var time: String }

    var body: some View {
        let s = store.query("reminders", "reminder", as: Setting.self) ?? Setting(on: false, time: "08:00")
        Section {
            Toggle(isOn: Binding(get: { s.on }, set: { on in
                Task { denied = !(await Reminders.setOn(on, store: store)) && on }
            })) { Label("Workout day reminder", systemImage: "bell") }
            if s.on {
                DatePicker("Time", selection: Binding(get: { Self.date(s.time) }, set: { d in
                    Task { await Reminders.setTime(d, store: store) }
                }), displayedComponents: .hourAndMinute)
            }
        } footer: {
            Text(denied ? "Notifications are off for GymFree. Turn them on in the Settings app to get reminders."
                        : "Reminds you at this time on days that have a routine planned, unless you've already trained.")
        }
    }

    private static func date(_ hhmm: String) -> Date {
        let parts = hhmm.split(separator: ":").compactMap { Int($0) }
        return Calendar.current.date(bySettingHour: parts.first ?? 8, minute: parts.count > 1 ? parts[1] : 0, second: 0, of: Date()) ?? Date()
    }
}
