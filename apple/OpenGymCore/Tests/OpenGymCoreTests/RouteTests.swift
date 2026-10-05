import Foundation
import Testing
@testable import OpenGymCore

/// A point `north` and `east` metres from a fixed origin (Zurich), at time `t`.
private func pt(_ north: Double, _ east: Double, t: Double, acc: Double = 5, alt: Double? = nil) -> TrackPoint {
    let lat0 = 47.3769, lon0 = 8.5417
    let lat = lat0 + north / 111_195.0
    let lon = lon0 + east / (111_195.0 * cos(lat0 * .pi / 180))
    return TrackPoint(lat: lat, lon: lon, alt: alt, t: t, acc: acc, vacc: alt == nil ? nil : 3)
}

struct RouteMathTests {
    @Test func distanceIsHaversine() {
        // One degree of latitude is about 111.2 km.
        let a = TrackPoint(lat: 0, lon: 0, t: 0, acc: 5)
        let b = TrackPoint(lat: 1, lon: 0, t: 1, acc: 5)
        #expect(abs(RouteMath.distance(a, b) - 111_195) < 10)
        // Zurich to Bern, about 95.5 km as the crow flies.
        let zh = TrackPoint(lat: 47.3769, lon: 8.5417, t: 0, acc: 5)
        let be = TrackPoint(lat: 46.9480, lon: 7.4474, t: 0, acc: 5)
        #expect(abs(RouteMath.distance(zh, be) - 95_500) < 1_000)
        #expect(RouteMath.distance(zh, zh) == 0)
    }

    @Test func lengthAddsUpStretchesButNotThePauseGap() {
        let first = (0...10).map { pt(Double($0) * 10, 0, t: Double($0) * 5) }        // 100 m north
        let second = (0...5).map { pt(500, Double($0) * 20, t: 200 + Double($0) * 5) } // 100 m east, far away
        #expect(abs(RouteMath.length(first) - 100) < 0.5)
        #expect(abs(RouteMath.length(segments: [first, second]) - 200) < 1)
        #expect(RouteMath.length([]) == 0)
        #expect(RouteMath.length([first[0]]) == 0)
    }

    @Test func paceAndSpeed() {
        // 5 km in 30 minutes: 6:00 per km, 10 km/h.
        #expect(RouteMath.pace(seconds: 1800, meters: 5000) == 360)
        #expect(RouteMath.speedKmh(seconds: 1800, meters: 5000) == 10)
        // Per mile: 1609.344 m in 10 minutes.
        #expect(abs((RouteMath.pace(seconds: 600, meters: 1609.344, perMeters: 1609.344) ?? 0) - 600) < 0.001)
        // Nothing to divide by yet, or standing still for ages.
        #expect(RouteMath.pace(seconds: 60, meters: 2) == nil)
        #expect(RouteMath.pace(seconds: 0, meters: 500) == nil)
        #expect(RouteMath.pace(seconds: 7200, meters: 10) == nil)
        #expect(RouteMath.speedKmh(seconds: 0, meters: 100) == 0)
    }

    @Test func recentPaceLooksAtTheLastHalfMinute() throws {
        // Slow (2 m/s) for a minute, then fast (4 m/s) for a minute.
        var pts: [TrackPoint] = []
        var north = 0.0
        for s in 0...120 {
            pts.append(pt(north, 0, t: Double(s)))
            north += s < 60 ? 2 : 4
        }
        let recent = try #require(RouteMath.recentPace(pts, window: 30))
        #expect(abs(recent - 250) < 5)   // 4 m/s is 250 s per km
        #expect(RouteMath.recentPace(Array(pts.prefix(3))) == nil)
    }

    @Test func ascentIgnoresNoiseOnTheFlat() {
        let flat = (0..<50).map { pt(Double($0) * 5, 0, t: Double($0), alt: 400 + ($0 % 2 == 0 ? 1.5 : -1.5)) }
        #expect(RouteMath.ascent(segments: [flat]) == 0)
        let hill = (0..<21).map { pt(Double($0) * 5, 0, t: Double($0), alt: 400 + Double($0)) }
        let climbed = RouteMath.ascent(segments: [hill])
        #expect(climbed >= 14 && climbed <= 20, "about 20 m up, counted in steps of 3 m: \(climbed)")
    }

    @Test func formatting() {
        let km = MotionFormat(imperial: false), mi = MotionFormat(speedUnit: "mph")
        #expect(km.pace(359.6) == "6:00")
        #expect(km.pace(nil) == "–:––")
        #expect(km.distanceUnit == "km" && mi.distanceUnit == "mi")
        #expect(mi.perMeters == 1609.344)
        #expect(MotionFormat.clock(65) == "1:05")
        #expect(MotionFormat.clock(3909) == "1:05:09")
    }
}

struct RouteFilterTests {
    @Test func dropsInaccurateInvalidStaleAndOutOfOrderFixes() {
        var f = RouteFilter(kind: .walk, notBefore: 100)
        let steps: [(TrackPoint, Bool, String)] = [
            (pt(0, 0, t: 50), false, "cached from before the start"),
            (pt(0, 0, t: 101, acc: 35), false, "too inaccurate"),
            (pt(0, 0, t: 101, acc: -1), false, "invalid"),
            (pt(0, 0, t: 102), true, "first good fix"),
            (pt(5, 0, t: 101), false, "older than the last"),
            (pt(5, 0, t: 102), false, "same time as the last"),
            (pt(5, 0, t: 104), true, "moving on"),
        ]
        for (p, keep, why) in steps {
            let kept = f.accept(p) != nil
            #expect(kept == keep, Comment(rawValue: why))
        }
    }

    @Test func standingStillAddsNoDistance() {
        var f = RouteFilter(kind: .walk)
        var kept: [TrackPoint] = []
        // Ten minutes of jitter within ±4 m around one spot.
        for s in 0..<600 {
            let jitter = Double((s * 7919) % 9) - 4
            if let p = f.accept(pt(jitter, -jitter / 2, t: Double(s), acc: 8)) { kept.append(p) }
        }
        #expect(RouteMath.length(kept) < 15, "jitter stays out of the distance: \(RouteMath.length(kept))")
    }

    @Test func dropsAJumpButKeepsWalking() {
        var f = RouteFilter(kind: .walk)
        var kept: [TrackPoint] = []
        for s in 0..<120 {
            // 1.5 m/s north, with one fix 300 m off to the east at 60 s.
            let p = s == 60 ? pt(Double(s) * 1.5, 300, t: Double(s)) : pt(Double(s) * 1.5, 0, t: Double(s))
            if let k = f.accept(p) { kept.append(k) }
        }
        let length = RouteMath.length(kept)
        #expect(abs(length - 178.5) < 12, "about 178.5 m walked: \(length)")
        #expect(kept.map { abs($0.lon - pt(0, 0, t: 0).lon) }.max()! < 0.0005, "the jump is not on the line")
    }

    @Test func smoothingPullsWobblyFixesLessThanSharpOnes() throws {
        var sharp = RouteFilter(kind: .walk), wobbly = RouteFilter(kind: .walk)
        _ = sharp.accept(pt(0, 0, t: 0, acc: 5))
        _ = wobbly.accept(pt(0, 0, t: 0, acc: 5))
        let a = sharp.accept(pt(20, 0, t: 10, acc: 3))
        let b = wobbly.accept(pt(20, 0, t: 10, acc: 19))
        let origin = pt(0, 0, t: 0)
        let da = RouteMath.distance(origin, try #require(a)), db = RouteMath.distance(origin, try #require(b))
        #expect(da > db, "\(da) vs \(db)")
        #expect(da <= 20.01)
    }

    @Test func restartBeginsAFreshStretch() throws {
        var f = RouteFilter(kind: .run)
        _ = f.accept(pt(0, 0, t: 0))
        _ = f.accept(pt(10, 0, t: 3))
        f.restart()
        #expect(f.last == nil)
        // A kilometre away after the pause: not a jump, a new stretch.
        let kept = f.accept(pt(1000, 0, t: 10))
        let p = try #require(kept)
        #expect(RouteMath.distance(p, pt(1000, 0, t: 10)) < 0.01)
    }

    @Test func pointsRoundTripThroughJSON() throws {
        let p = pt(12, 34, t: 1_700_000_000.5, acc: 4.2, alt: 410.3)
        let data = try JSONEncoder().encode([p])
        #expect(String(decoding: data, as: UTF8.self).contains("\"a\""))
        #expect(try JSONDecoder().decode([TrackPoint].self, from: data) == [p])
    }
}

@Suite(.serialized) @MainActor
struct ActivityStoreTests {
    @Test func aTrackedWalkIsInHistoryWithItsDistance() throws {
        let store = GymStore(storage: MemoryStorage())
        let start = Date(timeIntervalSince1970: 1_790_000_000)
        let rec = ActivityRecord(kind: .walk, start: start, end: start.addingTimeInterval(40 * 60),
                                 movingSec: 36 * 60, meters: 3240, ascent: 12, hasRoute: true)
        let key = try #require(store.logActivity(rec))
        let row = try #require(store.historyRows().first)
        #expect(row.key == key)
        #expect(row.activity == "walk")
        #expect(row.line.contains("3.24 km"))
        let detail = try #require(store.workoutDetail(key))
        let a = try #require(detail.activity)
        #expect(a.activityKind == .walk)
        #expect(a.meters == 3240)
        #expect(a.route)
        #expect(a.pace == "11:07 /km")
        #expect(store.activityKeys() == [key])
        let uuid = UUID()
        store.setActivityHealthId(key, uuid)
        #expect(store.workoutDetail(key)?.activity?.hk == uuid.uuidString)
        // A strength workout's detail has none.
        #expect(store.workouts.first?.entries.first?.sets.first?.min == 36)
    }
}
