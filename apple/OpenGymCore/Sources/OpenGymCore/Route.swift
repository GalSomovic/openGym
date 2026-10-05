import Foundation

// GPS tracking maths for walks, runs and rides (GymFree addition): what counts as a usable fix,
// the smoothing, and distance, pace and climb. Pure value types with no CoreLocation, so they
// can be tested anywhere; the app turns CLLocations into TrackPoints at the edge.

/// What is being tracked. The raw value is what the profile stores (apple/core/activity.js).
public enum ActivityKind: String, Codable, CaseIterable, Sendable, Identifiable {
    case walk, run, cycle

    public var id: String { rawValue }

    /// The fastest believable speed in m/s; anything faster between two fixes is a GPS jump.
    public var maxSpeed: Double {
        switch self {
        case .walk: 7      // brisk walking plus the odd jog to a crossing
        case .run: 12      // faster than a world-record sprint
        case .cycle: 30    // a fast descent
        }
    }

    /// Below this distance from the last kept point a fix is noise, not movement.
    public var minStep: Double { self == .cycle ? 5 : 3 }
}

/// One GPS fix: degrees, metres, seconds since 1970.
public struct TrackPoint: Codable, Hashable, Sendable {
    public var lat: Double
    public var lon: Double
    /// Metres above sea level; nil when unknown.
    public var alt: Double?
    public var t: Double
    /// Radius of uncertainty in metres; negative means invalid (CoreLocation's convention).
    public var acc: Double
    /// Vertical accuracy in metres; nil or negative when the altitude is not usable.
    public var vacc: Double?

    public init(lat: Double, lon: Double, alt: Double? = nil, t: Double, acc: Double, vacc: Double? = nil) {
        self.lat = lat; self.lon = lon; self.alt = alt; self.t = t; self.acc = acc; self.vacc = vacc
    }

    public var date: Date { Date(timeIntervalSince1970: t) }

    // Short keys on disk: a long route is thousands of these.
    enum CodingKeys: String, CodingKey { case lat = "a", lon = "o", alt = "h", t, acc = "e", vacc = "v" }
}

public enum RouteMath {
    /// Mean Earth radius (IUGG), metres.
    public static let earthRadius = 6_371_008.8

    /// Great-circle distance in metres (haversine): plenty for points metres apart.
    public static func distance(_ a: TrackPoint, _ b: TrackPoint) -> Double {
        let rad = Double.pi / 180
        let dLat = (b.lat - a.lat) * rad, dLon = (b.lon - a.lon) * rad
        let h = sin(dLat / 2) * sin(dLat / 2) + cos(a.lat * rad) * cos(b.lat * rad) * sin(dLon / 2) * sin(dLon / 2)
        return 2 * earthRadius * asin(min(1, sqrt(h)))
    }

    /// The length of one unbroken stretch of route.
    public static func length(_ points: [TrackPoint]) -> Double {
        zip(points, points.dropFirst()).reduce(0) { $0 + distance($1.0, $1.1) }
    }

    /// Every stretch together; the gap across a pause is not walked, so it does not count.
    public static func length(segments: [[TrackPoint]]) -> Double {
        segments.reduce(0) { $0 + length($1) }
    }

    /// Seconds per kilometre (or per mile with `perMeters: 1609.344`); nil when it means nothing.
    public static func pace(seconds: Double, meters: Double, perMeters: Double = 1000) -> Double? {
        guard meters >= 10, seconds > 0 else { return nil }
        let p = seconds / (meters / perMeters)
        return p.isFinite && p < 100 * 60 ? p : nil
    }

    /// km/h.
    public static func speedKmh(seconds: Double, meters: Double) -> Double {
        seconds > 0 ? (meters / 1000) / (seconds / 3600) : 0
    }

    /// The pace over roughly the last `window` seconds of the current stretch, or nil while
    /// there is too little of it to say.
    public static func recentPace(_ points: [TrackPoint], window: Double = 30, perMeters: Double = 1000) -> Double? {
        guard let last = points.last else { return nil }
        var meters = 0.0
        var first = last
        for (a, b) in zip(points.dropLast(), points.dropFirst()).reversed() {
            meters += distance(a, b)
            first = a
            if last.t - a.t >= window { break }
        }
        let seconds = last.t - first.t
        guard seconds >= min(10, window) else { return nil }
        return pace(seconds: seconds, meters: meters, perMeters: perMeters)
    }

    /// Metres climbed. Altitudes are averaged over the last five usable fixes, and a rise only
    /// counts once it passes `threshold`, so altitude noise on the flat does not add up. Fixes
    /// without a usable altitude are skipped.
    public static func ascent(segments: [[TrackPoint]], threshold: Double = 3) -> Double {
        var total = 0.0
        for seg in segments {
            var base: Double?
            var recent: [Double] = []
            for p in seg {
                guard let alt = p.alt, (p.vacc ?? 0) >= 0, (p.vacc ?? 0) <= 15 else { continue }
                recent.append(alt)
                if recent.count > 5 { recent.removeFirst() }
                let smooth = recent.reduce(0, +) / Double(recent.count)
                guard let b = base else { base = smooth; continue }
                if smooth - b >= threshold { total += smooth - b; base = smooth }
                else if smooth < b { base = smooth }
            }
        }
        return total
    }
}

/// Decides which GPS fixes become the route, one at a time, as they arrive.
///
/// 1. A fix less accurate than `maxAccuracy` (20 m) is dropped, as is one that is invalid,
///    older than the last, or stale (from before tracking started).
/// 2. The rest are smoothed by a small Kalman filter that weighs each fix by its accuracy, so
///    a wobbly fix moves the line less than a sharp one.
/// 3. A smoothed fix that would mean moving faster than the activity allows is a jump and is
///    dropped; one closer than `minStep` to the last kept point is standing still, not movement.
public struct RouteFilter: Sendable {
    public var maxAccuracy: Double
    public var maxSpeed: Double
    public var minStep: Double
    /// How fast the filter lets the position drift between fixes, m/s (process noise).
    public var drift: Double
    /// Fixes timestamped before this are cached positions from before the start.
    public var notBefore: Double

    /// The last kept point.
    public private(set) var last: TrackPoint?
    private var est: (lat: Double, lon: Double, variance: Double, t: Double)?

    public init(kind: ActivityKind = .walk, maxAccuracy: Double = 20, notBefore: Double = 0) {
        self.maxAccuracy = maxAccuracy
        self.maxSpeed = kind.maxSpeed
        self.minStep = kind.minStep
        self.drift = kind == .cycle ? 8 : 3
        self.notBefore = notBefore
    }

    /// Starts a new stretch (after a pause): the next good fix is kept as it is.
    public mutating func restart() {
        last = nil
        est = nil
    }

    /// The point to add to the route, or nil when this fix should not be.
    public mutating func accept(_ p: TrackPoint) -> TrackPoint? {
        guard p.acc >= 0, p.acc <= maxAccuracy, p.t >= notBefore,
              abs(p.lat) <= 90, abs(p.lon) <= 180 else { return nil }
        if let e = est, p.t <= e.t { return nil }

        // Kalman step, with the variance in metres².
        var smoothed = p
        if var e = est {
            let dt = p.t - e.t
            e.variance += dt * drift * drift
            let k = e.variance / (e.variance + p.acc * p.acc)
            e.lat += k * (p.lat - e.lat)
            e.lon += k * (p.lon - e.lon)
            e.variance *= (1 - k)
            e.t = p.t
            smoothed.lat = e.lat
            smoothed.lon = e.lon
            // Speed check against the last kept point before the estimate moves on.
            if let l = last {
                let dist = RouteMath.distance(l, smoothed)
                let secs = p.t - l.t
                if secs > 0, dist / secs > maxSpeed { return nil }
                est = e
                if dist < minStep { return nil }
            } else {
                est = e
            }
        } else {
            est = (p.lat, p.lon, p.acc * p.acc, p.t)
        }
        last = smoothed
        return smoothed
    }
}

/// Distances, paces and speeds as the screens show them, in kilometres or miles (openGym's
/// speed unit decides: "mph" means miles).
public struct MotionFormat: Sendable {
    public var imperial: Bool

    public init(imperial: Bool) { self.imperial = imperial }
    public init(speedUnit: String?) { imperial = speedUnit == "mph" }

    public var perMeters: Double { imperial ? 1609.344 : 1000 }
    public var distanceUnit: String { imperial ? "mi" : "km" }
    public var speedUnit: String { imperial ? "mph" : "km/h" }

    /// "2.34" (without the unit).
    public func distance(_ meters: Double) -> String {
        (meters / perMeters).formatted(.number.precision(.fractionLength(2)))
    }

    /// "5:41" per km or mi, "–:––" when there is none yet.
    public func pace(_ secondsPerUnit: Double?) -> String {
        guard let s = secondsPerUnit, s.isFinite, s > 0 else { return "–:––" }
        var m = Int(s / 60)
        var r = Int((s - Double(m) * 60).rounded())
        if r == 60 { m += 1; r = 0 }
        return String(format: "%d:%02d", m, r)
    }

    /// "18.2" km/h or mph (without the unit).
    public func speed(kmh: Double) -> String {
        (imperial ? kmh / 1.609344 : kmh).formatted(.number.precision(.fractionLength(1)))
    }

    /// "1:05:09" or "32:10".
    public static func clock(_ seconds: Double) -> String {
        let s = max(0, Int(seconds))
        return s >= 3600 ? String(format: "%d:%02d:%02d", s / 3600, s / 60 % 60, s % 60) : String(format: "%d:%02d", s / 60, s % 60)
    }
}
