import Observation
import OpenGymCore
import SwiftUI
import UserNotifications

/// The live parts of a workout that are not in the profile: the rest timer, a timed hold, and
/// the cues and prompts that follow a ticked set. openGym keeps these in its UI store
/// (store/useUI.js); what happens after each tick is decided by the engine (toggleSet).
@MainActor
@Observable
final class WorkoutSession {
    struct Rest: Equatable {
        var endsAt: Date
        var total: Double
        /// The exercise whose set earned this rest.
        var forIdx: Int
        /// Set while paused: the seconds that were left.
        var paused: Double?
        /// Ran out: shows "Ready" until the next set or a tap.
        var ready = false

        func remaining(at now: Date = .now) -> Double { paused ?? max(0, endsAt.timeIntervalSince(now)) }
        var running: Bool { !ready && paused == nil }
    }

    struct Hold: Equatable {
        var entry: Int
        var set: Int
        var plan: Double
        var startedAt: Date
        var endsAt: Date { startedAt.addingTimeInterval(plan) }
    }

    var rest: Rest?
    var hold: Hold?
    var completePrompt = false
    var toast: String?

    let cues = CuePlayer()
    @ObservationIgnored private let store: GymStore
    @ObservationIgnored private var ticker: Task<Void, Never>?
    @ObservationIgnored private var lastCountdown = -1
    private static let restNotification = "gymfree.rest"

    init(store: GymStore) {
        self.store = store
    }

    var restRunning: Bool { rest?.running == true }

    func syncSettings() {
        cues.enabled = store.pick("sound", as: Bool.self) ?? true
    }

    /* ------------------------------ sets ------------------------------ */

    func toggle(_ entry: Int, _ set: Int, side: String? = nil) {
        guard let outcome = store.toggleSet(entry, set, side: side, timerRunning: restRunning) else { return }
        apply(outcome)
    }

    /// An effort rating concludes the set (openGym #64): rate it and it is ticked.
    func rate(_ entry: Int, _ set: Int, field: String, value: Double?, side: String? = nil) {
        if let side { store.setSideValue(entry, set, side, field, value) } else { store.setTyped(entry, set, field, value) }
        guard value != nil, let row = store.active?.entries[safe: entry]?.sets[safe: set] else { return }
        let done = side.map { row.sides?[$0]?.done == true } ?? row.isDone
        if !done { toggle(entry, set, side: side) }
    }

    private func apply(_ o: ToggleOutcome) {
        if o.checked {
            if o.beep { cues.tick() }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        if o.stopRest { stopRest() }
        if let r = o.rest { startRest(r.sec, forIdx: r.forIdx) }
        if o.complete {
            stopRest()
            completePrompt = true
        } else if o.toast == "cardio" {
            toast = String(localized: "Cardio logged")
        } else if o.toast == "hold" {
            toast = String(localized: "Hold logged")
        }
    }

    /* ------------------------------ rest ------------------------------ */

    func startRest(_ seconds: Double, forIdx: Int) {
        guard seconds > 0, store.active?.isBackfill != true else { return }
        abandonHold()
        rest = Rest(endsAt: .now.addingTimeInterval(seconds), total: seconds, forIdx: forIdx)
        lastCountdown = -1
        scheduleRestNotification(at: rest!.endsAt)
        runTicker()
    }

    func adjustRest(_ delta: Double) {
        guard var r = rest, !r.ready else { return }
        if let p = r.paused {
            r.paused = max(0, p + delta)
        } else {
            r.endsAt = max(.now, r.endsAt.addingTimeInterval(delta))
            scheduleRestNotification(at: r.endsAt)
        }
        r.total = max(r.total + delta, r.remaining())
        rest = r
    }

    func togglePause() {
        guard var r = rest, !r.ready else { return }
        if let p = r.paused {
            r.endsAt = .now.addingTimeInterval(p)
            r.paused = nil
            scheduleRestNotification(at: r.endsAt)
        } else {
            r.paused = r.remaining()
            cancelRestNotification()
        }
        rest = r
    }

    func stopRest() {
        rest = nil
        cancelRestNotification()
    }

    /// Keeps the rest with its exercise when exercises are removed or moved.
    func exerciseRemoved(_ idx: Int) {
        guard let r = rest else { return }
        if r.forIdx == idx { stopRest() } else if r.forIdx > idx { rest?.forIdx -= 1 }
    }

    func exercisesReordered(_ order: [Int]?) {
        guard let order, let r = rest, let at = order.firstIndex(of: r.forIdx) else { return }
        rest?.forIdx = at
    }

    func exerciseInserted(at idx: Int) {
        guard let r = rest, r.forIdx >= idx else { return }
        rest?.forIdx += 1
    }

    /* ------------------------------ timed holds ------------------------------ */

    /// Starts holding a timed set; the row's plan is its seconds.
    func startHold(_ entry: Int, _ set: Int, plan: Double) {
        stopRest()
        hold = Hold(entry: entry, set: set, plan: max(1, plan), startedAt: .now)
        lastCountdown = -1
        runTicker()
    }

    /// "Done" before the time is up: logs what was actually held.
    func finishHoldEarly() {
        guard let h = hold else { return }
        endHold(h, elapsed: Date.now.timeIntervalSince(h.startedAt).rounded(), chimed: false)
    }

    func cancelHold() { hold = nil }

    /// A rest that displaces a running hold keeps the hold's seconds and nothing else.
    private func abandonHold() {
        guard let h = hold else { return }
        hold = nil
        store.recordHold(h.entry, h.set, elapsed: Date.now.timeIntervalSince(h.startedAt).rounded(), abandoned: true,
                         plan: h.plan, timerRunning: false, quiet: true)
    }

    private func endHold(_ h: Hold, elapsed: Double, chimed: Bool) {
        hold = nil
        if let outcome = store.recordHold(h.entry, h.set, elapsed: max(1, elapsed), abandoned: false, plan: h.plan,
                                          timerRunning: restRunning, quiet: chimed) {
            apply(outcome)
        }
    }

    /* ------------------------------ the clock ------------------------------ */

    private func runTicker() {
        guard ticker == nil else { return }
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                guard let self else { return }
                if !self.tick() { self.ticker = nil; return }
            }
        }
    }

    /// Returns whether anything is still being timed.
    private func tick() -> Bool {
        let now = Date.now
        if let h = hold {
            let left = h.endsAt.timeIntervalSince(now)
            countdownCue(left)
            if left <= 0 {
                cues.restOver()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                endHold(h, elapsed: h.plan, chimed: true)
            }
            return true
        }
        if var r = rest, r.running {
            let left = r.remaining(at: now)
            countdownCue(left)
            if left <= 0 {
                r.ready = true
                rest = r
                cues.restOver()
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
            return true
        }
        return false
    }

    /// One short note at 3, 2 and 1 seconds left.
    private func countdownCue(_ left: Double) {
        let s = Int(left.rounded(.up))
        guard (1...3).contains(s), s != lastCountdown else { return }
        lastCountdown = s
        cues.countdown()
    }

    /* ------------------------------ background ------------------------------ */

    private func scheduleRestNotification(at date: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Self.restNotification])
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Rest over")
        content.body = String(localized: "Time for your next set.")
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        let interval = max(1, date.timeIntervalSinceNow)
        let request = UNNotificationRequest(identifier: Self.restNotification, content: content,
                                            trigger: UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false))
        Task {
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
            if granted { try? await center.add(request) }
        }
    }

    private func cancelRestNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.restNotification])
    }
}

extension Array {
    subscript(safe index: Int) -> Element? { indices.contains(index) ? self[index] : nil }
}
