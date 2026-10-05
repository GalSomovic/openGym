import Foundation
import Observation
import OpenGymCore

/// A GPS walk, run or ride in progress: the route as it grows, distance and moving time, pause
/// and resume, then filing it in the history (activity.js), its route in a file on the device
/// (RouteStore) and, when the user chose so, the workout and route in Apple Health.
///
/// Independent of the strength session: it lives in AppServices, so leaving the tracking screen
/// or locking the phone does not stop it.
@MainActor
@Observable
final class ActivityTracker {
    enum Phase: Equatable { case idle, running, paused }

    /// What was just saved, for the summary.
    struct Finished: Equatable {
        var key: String?
        var kind: ActivityKind
        var start: Date
        var meters: Double
        var movingSec: Double
        var ascent: Double
        var segments: [[TrackPoint]]
        static func == (a: Finished, b: Finished) -> Bool { a.key == b.key && a.start == b.start }
    }

    private(set) var phase: Phase = .idle
    private(set) var kind: ActivityKind = .walk
    private(set) var segments: [[TrackPoint]] = []
    private(set) var meters: Double = 0
    private(set) var startedAt: Date?
    private(set) var permission: LocationPermission
    /// The latest fix, kept or not: the GPS quality and where you are before starting.
    private(set) var lastFix: TrackPoint?
    /// Location updates are running (on the start screen too, to find the GPS).
    private(set) var watching = false
    private(set) var finished: Finished?
    /// An activity the app was closed during, from its draft.
    private(set) var recovered: RouteStore.Draft?

    @ObservationIgnored private let store: GymStore
    @ObservationIgnored private let health: HealthSync
    @ObservationIgnored private let source: LocationSource
    @ObservationIgnored private let routes: RouteStore
    @ObservationIgnored private let live = MotionLiveActivityController()
    @ObservationIgnored private var filter = RouteFilter()
    @ObservationIgnored private var recorder: HealthWorkoutRecorder?
    @ObservationIgnored private var movingBefore: Double = 0
    @ObservationIgnored private var runningSince: Date?
    @ObservationIgnored private var lastDraft = Date.distantPast
    @ObservationIgnored private var lastLive = Date.distantPast

    init(store: GymStore, health: HealthSync, routes: RouteStore = .standard) {
        self.store = store
        self.health = health
        self.routes = routes
        #if DEBUG
        source = DebugLaunch.fakeRoute ? FakeLocationSource() : CoreLocationSource()
        #else
        source = CoreLocationSource()
        #endif
        permission = source.permission
        recovered = routes.loadDraft()
        source.onPoints = { [weak self] in self?.receive($0) }
        source.onPermission = { [weak self] p in
            guard let self else { return }
            self.permission = p
            if self.wantsWatching, p == .allowed || p == .approximate { self.startWatching() }
        }
        live.endLeftovers()
    }

    var isActive: Bool { phase != .idle }
    @ObservationIgnored private var wantsWatching = false

    /// Seconds moving: the clock runs while not paused.
    func movingSeconds(at now: Date = .now) -> Double {
        movingBefore + (runningSince.map { max(0, now.timeIntervalSince($0)) } ?? 0)
    }

    /// The pace over the last half minute of the current stretch.
    func currentPace(perMeters: Double) -> Double? {
        phase == .running ? RouteMath.recentPace(segments.last ?? [], window: 30, perMeters: perMeters) : nil
    }

    /* ------------------------------ before starting ------------------------------ */

    /// The start screen is up: find the GPS (asking for permission the first time).
    func prepare() {
        wantsWatching = true
        switch permission {
        case .notAsked: source.requestPermission()
        case .allowed, .approximate: startWatching()
        case .denied, .restricted: break
        }
    }

    /// The start screen closed without starting.
    func unprepare() {
        wantsWatching = false
        guard phase == .idle, watching else { return }
        source.stop()
        watching = false
    }

    private func startWatching() {
        guard !watching else { return }
        source.start(kind: kind)
        watching = true
    }

    func choose(_ kind: ActivityKind) {
        guard phase == .idle else { return }
        self.kind = kind
    }

    /* ------------------------------ tracking ------------------------------ */

    func start() {
        guard phase == .idle else { return }
        let now = Date.now
        finished = nil
        startedAt = now
        movingBefore = 0
        runningSince = now
        segments = [[]]
        meters = 0
        // A fix cached from before this moment is where you were, not where you are.
        filter = RouteFilter(kind: kind, notBefore: now.timeIntervalSince1970 - 2)
        phase = .running
        recorder = health.recorder(for: kind)
        recorder?.start(at: now)
        wantsWatching = true
        startWatching()
        saveDraft(force: true)
        publish(force: true)
    }

    func pause() {
        guard phase == .running else { return }
        let now = Date.now
        movingBefore = movingSeconds(at: now)
        runningSince = nil
        phase = .paused
        recorder?.pause(at: now)
        saveDraft(force: true)
        publish(force: true)
    }

    func resume() {
        guard phase == .paused else { return }
        let now = Date.now
        runningSince = now
        phase = .running
        // A new stretch: the way walked during the pause is not part of the route.
        segments.append([])
        filter.restart()
        recorder?.resume(at: now)
        saveDraft(force: true)
        publish(force: true)
    }

    private func receive(_ points: [TrackPoint]) {
        lastFix = points.last ?? lastFix
        guard phase == .running, !segments.isEmpty else { return }
        var kept: [TrackPoint] = []
        for p in points {
            guard let k = filter.accept(p) else { continue }
            if let prev = segments[segments.count - 1].last { meters += RouteMath.distance(prev, k) }
            segments[segments.count - 1].append(k)
            kept.append(k)
        }
        guard !kept.isEmpty else { return }
        recorder?.add(kept)
        saveDraft()
        publish()
    }

    /// Files the activity. The summary is in `finished` until it is closed.
    func finish() {
        guard phase != .idle, let start = startedAt else { return }
        let now = Date.now
        let moving = movingSeconds(at: now)
        let segs = segments.filter { !$0.isEmpty }
        let ascent = RouteMath.ascent(segments: segs)
        let hasRoute = segs.reduce(0) { $0 + $1.count } >= 2
        let record = ActivityRecord(kind: kind, start: start, end: max(now, start.addingTimeInterval(1)),
                                    movingSec: moving, meters: meters, ascent: ascent, hasRoute: hasRoute)
        let key = store.logActivity(record)
        if let key, hasRoute { try? routes.save(.init(kind: kind, segments: segs), key: key) }
        if let key, let recorder {
            let meters = self.meters
            Task {
                if let uuid = await recorder.finish(start: start, end: record.end, meters: meters, syncId: "gymfree-workout-\(key)") {
                    self.store.setActivityHealthId(key, uuid)
                }
            }
        } else {
            recorder?.discard()
        }
        finished = Finished(key: key, kind: kind, start: start, meters: meters, movingSec: moving, ascent: ascent, segments: segs)
        reset()
    }

    /// Throws the activity away: nothing is saved, in the history or in Health.
    func discard() {
        recorder?.discard()
        reset()
    }

    func closeSummary() { finished = nil }

    private func reset() {
        source.stop()
        watching = false
        wantsWatching = false
        recorder = nil
        phase = .idle
        startedAt = nil
        runningSince = nil
        movingBefore = 0
        segments = []
        meters = 0
        routes.deleteDraft()
        live.end()
    }

    /* ------------------------------ the draft ------------------------------ */

    /// Written every 15 seconds of tracking and when the app goes to the background.
    func saveDraft(force: Bool = false) {
        guard phase != .idle, let start = startedAt else { return }
        let now = Date.now
        guard force || now.timeIntervalSince(lastDraft) >= 15 else { return }
        lastDraft = now
        routes.saveDraft(.init(kind: kind, startedAt: start, movingSec: movingSeconds(at: now), savedAt: now, segments: segments))
    }

    /// Saves the activity the app was closed during, as far as it got.
    func saveRecovered() {
        guard let d = recovered else { return }
        recovered = nil
        let segs = d.segments.filter { !$0.isEmpty }
        let hasRoute = segs.reduce(0) { $0 + $1.count } >= 2
        let end = max(d.end, d.startedAt.addingTimeInterval(max(1, d.movingSec)))
        let record = ActivityRecord(kind: d.kind, start: d.startedAt, end: end, movingSec: d.movingSec,
                                    meters: d.meters, ascent: RouteMath.ascent(segments: segs), hasRoute: hasRoute)
        if let key = store.logActivity(record) {
            if hasRoute { try? routes.save(.init(kind: d.kind, segments: segs), key: key) }
            if let rec = health.recorder(for: d.kind) {
                rec.add(segs.flatMap { $0 })
                Task {
                    if let uuid = await rec.finish(start: d.startedAt, end: end, meters: record.meters, syncId: "gymfree-workout-\(key)") {
                        self.store.setActivityHealthId(key, uuid)
                    }
                }
            }
        }
        routes.deleteDraft()
    }

    func discardRecovered() {
        recovered = nil
        routes.deleteDraft()
    }

    /* ------------------------------ the Lock Screen ------------------------------ */

    private func publish(force: Bool = false) {
        guard let start = startedAt else { return }
        let now = Date.now
        guard force || now.timeIntervalSince(lastLive) >= 10 else { return }
        lastLive = now
        let f = store.motionFormat
        let moving = movingSeconds(at: now)
        let detail: String
        if kind == .cycle {
            detail = "\(f.speed(kmh: RouteMath.speedKmh(seconds: moving, meters: meters))) \(f.speedUnit)"
        } else {
            detail = "\(f.pace(RouteMath.pace(seconds: moving, meters: meters, perMeters: f.perMeters))) /\(f.distanceUnit)"
        }
        let state = MotionActivityAttributes.ContentState(
            distance: "\(f.distance(meters)) \(f.distanceUnit)", detail: detail,
            clockStart: now.addingTimeInterval(-moving), pausedClock: phase == .paused ? MotionFormat.clock(moving) : nil)
        live.update(kind: kind.rawValue, name: kind.title, startedAt: start, state: state)
    }
}

extension ActivityKind {
    var title: String {
        switch self {
        case .walk: String(localized: "Walk")
        case .run: String(localized: "Run")
        case .cycle: String(localized: "Ride")
        }
    }

    var symbol: String {
        switch self {
        case .walk: "figure.walk"
        case .run: "figure.run"
        case .cycle: "figure.outdoor.cycle"
        }
    }
}
