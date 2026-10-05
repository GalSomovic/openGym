import Foundation
import HealthKit
import Observation
import OpenGymCore

/// Apple Health, opt-in (Settings → Apple Health). Nothing is asked for until the user turns
/// it on there. Writes strength workouts, GPS walks, runs and rides with their routes, and
/// weigh-ins; reads the latest body weight (to import) and steps (for the calorie estimate).
/// Everything stays on the device and in Health: GymFree has no server to send it to.
@MainActor
@Observable
final class HealthSync {
    enum Key {
        static let enabled = "gf.health"
        static let workouts = "gf.health.workouts"
        static let weight = "gf.health.weight"
    }

    /// iPad without Health, or a restricted device.
    let isAvailable = HKHealthStore.isHealthDataAvailable()
    /// The last thing that went wrong, for Settings to show.
    var lastError: String?
    var enabled: Bool {
        didSet { UserDefaults.standard.set(enabled, forKey: Key.enabled) }
    }

    @ObservationIgnored let hk = HKHealthStore()

    init() {
        UserDefaults.standard.register(defaults: [Key.workouts: true, Key.weight: true])
        enabled = UserDefaults.standard.bool(forKey: Key.enabled)
    }

    private var on: Bool { enabled && isAvailable && !DebugLaunch.noHealth }
    var writesWorkouts: Bool { on && UserDefaults.standard.bool(forKey: Key.workouts) }
    var writesWeight: Bool { on && UserDefaults.standard.bool(forKey: Key.weight) }
    var reads: Bool { on }

    static var bodyMass: HKQuantityType { HKQuantityType(.bodyMass) }
    static var steps: HKQuantityType { HKQuantityType(.stepCount) }

    private static var shareTypes: Set<HKSampleType> {
        [HKObjectType.workoutType(), HKSeriesType.workoutRoute(), bodyMass,
         HKQuantityType(.distanceWalkingRunning), HKQuantityType(.distanceCycling), HKQuantityType(.activeEnergyBurned)]
    }

    private static var readTypes: Set<HKObjectType> { [bodyMass, steps] }

    /* ------------------------------ permission ------------------------------ */

    /// Turns the connection on: the system's Health sheet asks for each kind of data once.
    @discardableResult
    func connect() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await hk.requestAuthorization(toShare: Self.shareTypes, read: Self.readTypes)
            lastError = nil
            enabled = true
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    /// Whether Health lets GymFree save workouts / weights (reading permission is never told).
    func mayWrite(_ type: HKObjectType) -> Bool { hk.authorizationStatus(for: type) == .sharingAuthorized }
    var mayWriteWorkouts: Bool { mayWrite(HKObjectType.workoutType()) }
    var mayWriteWeight: Bool { mayWrite(Self.bodyMass) }

    /// HealthKit replaces an earlier sample with the same sync identifier (and a lower version)
    /// instead of adding a second: a re-logged weigh-in or a saved-again workout never doubles.
    static func syncMetadata(_ id: String) -> [String: Any] {
        [HKMetadataKeySyncIdentifier: id, HKMetadataKeySyncVersion: Int(Date().timeIntervalSince1970)]
    }

    /* ------------------------------ writing ------------------------------ */

    /// A finished strength session: its start and end only. No calories: GymFree does not
    /// measure them and does not make them up.
    func saveStrength(_ w: Workout) {
        guard writesWorkouts, let s = w.start, let e = w.end, e > s else { return }
        let start = Date(timeIntervalSince1970: s / 1000), end = Date(timeIntervalSince1970: e / 1000)
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        config.locationType = .indoor
        let builder = HKWorkoutBuilder(healthStore: hk, configuration: config, device: .local())
        let meta = Self.syncMetadata("gymfree-workout-\(w.id)")
        Task {
            do {
                try await builder.beginCollection(at: start)
                try await builder.endCollection(at: end)
                try await builder.addMetadata(meta)
                _ = try await builder.finishWorkout()
            } catch {
                self.lastError = error.localizedDescription
            }
        }
    }

    /// A weigh-in, in the profile's unit. Today's is stamped now, a past day's at noon.
    func saveWeight(_ value: Double, unit: String, iso: String = Fmt.todayISO()) {
        guard writesWeight, value > 0 else { return }
        let q = HKQuantity(unit: unit == "lb" ? .pound() : .gramUnit(with: .kilo), doubleValue: value)
        let date = iso == Fmt.todayISO() ? Date.now : Day.date(iso)
        let sample = HKQuantitySample(type: Self.bodyMass, quantity: q, start: date, end: date,
                                      metadata: Self.syncMetadata("gymfree-bw-\(iso)"))
        Task {
            do { try await hk.save(sample) } catch { self.lastError = error.localizedDescription }
        }
    }

    /// A recorder for a GPS activity, when workouts go to Health.
    func recorder(for kind: ActivityKind) -> HealthWorkoutRecorder? {
        writesWorkouts ? HealthWorkoutRecorder(hk: hk, kind: kind) : nil
    }

    /* ------------------------------ reading ------------------------------ */

    struct BodyMass: Equatable {
        var kg: Double
        var date: Date
        /// Saved by GymFree itself (importing it would only copy it back).
        var ours: Bool
    }

    /// The most recent body weight in Health, from any app or scale.
    func latestBodyMass() async -> BodyMass? {
        guard reads else { return nil }
        let query = HKSampleQueryDescriptor(predicates: [.quantitySample(type: Self.bodyMass)],
                                            sortDescriptors: [SortDescriptor(\.endDate, order: .reverse)], limit: 1)
        guard let s = try? await query.result(for: hk).first else { return nil }
        return BodyMass(kg: s.quantity.doubleValue(for: .gramUnit(with: .kilo)), date: s.endDate,
                        ours: s.sourceRevision.source.bundleIdentifier == Bundle.main.bundleIdentifier)
    }

    /// The average daily steps over the last `days` full days, counting only days with any.
    func averageSteps(days: Int = 7) async -> Int? {
        guard reads else { return nil }
        let cal = Calendar.current
        let end = cal.startOfDay(for: .now)
        guard let start = cal.date(byAdding: .day, value: -days, to: end) else { return nil }
        let predicate = HKSamplePredicate.quantitySample(type: Self.steps,
                                                         predicate: HKQuery.predicateForSamples(withStart: start, end: end))
        let query = HKStatisticsCollectionQueryDescriptor(predicate: predicate, options: .cumulativeSum,
                                                          anchorDate: end, intervalComponents: DateComponents(day: 1))
        guard let collection = try? await query.result(for: hk) else { return nil }
        var total = 0.0, counted = 0
        collection.enumerateStatistics(from: start, to: end) { stats, _ in
            if let n = stats.sumQuantity()?.doubleValue(for: .count()), n > 0 { total += n; counted += 1 }
        }
        return counted > 0 ? Int((total / Double(counted)).rounded()) : nil
    }
}

/// One GPS activity on its way to Health: an `HKWorkoutSession` with its live builder while
/// tracking (iPhone runs workout sessions since iOS 26), and the route alongside. When a live
/// session cannot start, the workout is built at the end from the same data instead.
@MainActor
final class HealthWorkoutRecorder {
    private let hk: HKHealthStore
    private let kind: ActivityKind
    private let config: HKWorkoutConfiguration
    private var session: HKWorkoutSession?
    private var live: HKLiveWorkoutBuilder?
    private let route: HKWorkoutRouteBuilder
    private var routePoints = 0
    private var events: [HKWorkoutEvent] = []

    init(hk: HKHealthStore, kind: ActivityKind) {
        self.hk = hk
        self.kind = kind
        let c = HKWorkoutConfiguration()
        c.activityType = switch kind {
        case .walk: .walking
        case .run: .running
        case .cycle: .cycling
        }
        c.locationType = .outdoor
        config = c
        route = HKWorkoutRouteBuilder(healthStore: hk, device: .local())
    }

    private var distanceType: HKQuantityType {
        HKQuantityType(kind == .cycle ? .distanceCycling : .distanceWalkingRunning)
    }

    /// Starts the live session. Failing that, the workout is simply built at the end.
    func start(at date: Date) {
        do {
            let s = try HKWorkoutSession(healthStore: hk, configuration: config)
            let b = s.associatedWorkoutBuilder()
            let source = HKLiveWorkoutDataSource(healthStore: hk, workoutConfiguration: config)
            // The distance is the GPS route's, added at the end; not the pedometer's estimate.
            source.disableCollection(for: HKQuantityType(.distanceWalkingRunning))
            source.disableCollection(for: HKQuantityType(.distanceCycling))
            b.dataSource = source
            session = s
            live = b
            s.startActivity(with: date)
            Task {
                do { try await b.beginCollection(at: date) } catch { self.dropLive() }
            }
        } catch {
            dropLive()
        }
    }

    private func dropLive() {
        session?.end()
        live = nil
        session = nil
    }

    func add(_ points: [TrackPoint]) {
        guard !points.isEmpty else { return }
        routePoints += points.count
        let locations = points.map(\.location)
        Task {
            try? await route.insertRouteData(locations)
        }
    }

    func pause(at date: Date) {
        session?.pause()
        events.append(HKWorkoutEvent(type: .pause, dateInterval: DateInterval(start: date, duration: 0), metadata: nil))
    }

    func resume(at date: Date) {
        session?.resume()
        events.append(HKWorkoutEvent(type: .resume, dateInterval: DateInterval(start: date, duration: 0), metadata: nil))
    }

    /// Saves the workout, its distance and its route. Returns the Health workout's id.
    func finish(start: Date, end: Date, meters: Double, syncId: String) async -> UUID? {
        var samples: [HKSample] = []
        if meters >= 1 {
            samples.append(HKQuantitySample(type: distanceType, quantity: HKQuantity(unit: .meter(), doubleValue: meters),
                                            start: start, end: end))
        }
        var meta = HealthSync.syncMetadata(syncId)
        meta[HKMetadataKeyIndoorWorkout] = false
        do {
            let workout: HKWorkout?
            if let session, let live {
                session.end()
                try await live.endCollection(at: end)
                if !samples.isEmpty { try await live.addSamples(samples) }
                try await live.addMetadata(meta)
                workout = try await live.finishWorkout()
            } else {
                let b = HKWorkoutBuilder(healthStore: hk, configuration: config, device: .local())
                try await b.beginCollection(at: start)
                if !events.isEmpty { try await b.addWorkoutEvents(events) }
                if !samples.isEmpty { try await b.addSamples(samples) }
                try await b.endCollection(at: end)
                try await b.addMetadata(meta)
                workout = try await b.finishWorkout()
            }
            guard let workout else { return nil }
            if routePoints > 0 { _ = try? await route.finishRoute(with: workout, metadata: nil) }
            return workout.uuid
        } catch {
            route.discard()
            return nil
        }
    }

    func discard() {
        session?.end()
        live?.discardWorkout()
        route.discard()
        session = nil
        live = nil
    }
}
