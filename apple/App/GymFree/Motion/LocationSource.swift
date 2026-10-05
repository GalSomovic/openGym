import CoreLocation
import Foundation
import OpenGymCore

/// Where location permission stands, as the tracking screen needs it.
enum LocationPermission: Equatable {
    case notAsked, allowed, denied, restricted
    /// Location is on but "Precise Location" is off: fixes are kilometres wide.
    case approximate
}

/// Where GPS fixes come from: the real GPS, or a scripted route for UI tests and screenshots.
@MainActor
protocol LocationSource: AnyObject {
    var permission: LocationPermission { get }
    var onPoints: (([TrackPoint]) -> Void)? { get set }
    var onPermission: ((LocationPermission) -> Void)? { get set }
    func requestPermission()
    func start(kind: ActivityKind)
    func stop()
}

/// CoreLocation, "When In Use" only: tracking starts in the foreground and carries on with the
/// screen locked through the `location` background mode (the blue pill shows it is running).
@MainActor
final class CoreLocationSource: NSObject, LocationSource, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var background: CLBackgroundActivitySession?
    var onPoints: (([TrackPoint]) -> Void)?
    var onPermission: ((LocationPermission) -> Void)?

    override init() {
        super.init()
        manager.delegate = self
        manager.activityType = .fitness
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.pausesLocationUpdatesAutomatically = false
    }

    var permission: LocationPermission { Self.permission(manager) }

    nonisolated private static func permission(_ m: CLLocationManager) -> LocationPermission {
        switch m.authorizationStatus {
        case .notDetermined: .notAsked
        case .restricted: .restricted
        case .denied: .denied
        default: m.accuracyAuthorization == .reducedAccuracy ? .approximate : .allowed
        }
    }

    func requestPermission() { manager.requestWhenInUseAuthorization() }

    func start(kind: ActivityKind) {
        manager.distanceFilter = kind == .cycle ? 5 : 2
        manager.activityType = kind == .cycle ? .otherNavigation : .fitness
        manager.allowsBackgroundLocationUpdates = true
        manager.showsBackgroundLocationIndicator = true
        background = CLBackgroundActivitySession()
        manager.startUpdatingLocation()
    }

    func stop() {
        manager.stopUpdatingLocation()
        manager.allowsBackgroundLocationUpdates = false
        background?.invalidate()
        background = nil
    }

    // The manager was made on the main thread, so its delegate is called there.
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let points = locations.map(TrackPoint.init)
        MainActor.assumeIsolated { onPoints?(points) }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let p = Self.permission(manager)
        MainActor.assumeIsolated { onPermission?(p) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // kCLErrorLocationUnknown is temporary (no fix yet); a denial arrives as an
        // authorization change. Either way the tracker simply waits for the next fix.
    }
}

extension TrackPoint {
    init(_ l: CLLocation) {
        self.init(lat: l.coordinate.latitude, lon: l.coordinate.longitude,
                  alt: l.verticalAccuracy >= 0 ? l.altitude : nil,
                  t: l.timestamp.timeIntervalSince1970, acc: l.horizontalAccuracy,
                  vacc: l.verticalAccuracy >= 0 ? l.verticalAccuracy : nil)
    }

    var coordinate: CLLocationCoordinate2D { CLLocationCoordinate2D(latitude: lat, longitude: lon) }

    var location: CLLocation {
        CLLocation(coordinate: coordinate, altitude: alt ?? 0, horizontalAccuracy: acc,
                   verticalAccuracy: alt == nil ? -1 : (vacc ?? 10), timestamp: date)
    }
}

#if DEBUG
/// A scripted loop for UI tests and screenshots (-GFFakeRoute YES): a fix every half second,
/// each one five seconds of walking further, with an inaccurate fix and a GPS jump mixed in for the filter
/// to drop. Its clock runs ahead of the real one, so a few seconds make a short walk.
@MainActor
final class FakeLocationSource: LocationSource {
    var permission: LocationPermission = .allowed
    var onPoints: (([TrackPoint]) -> Void)?
    var onPermission: ((LocationPermission) -> Void)?
    private var task: Task<Void, Never>?

    func requestPermission() { onPermission?(.allowed) }

    func start(kind: ActivityKind) {
        task?.cancel()
        let speed = kind == .cycle ? 6.0 : kind == .run ? 3.2 : 1.6   // m/s
        task = Task { [weak self] in
            let t0 = Date.now.timeIntervalSince1970
            var n = 0
            // A 400 m loop around a park in Zurich.
            let lat0 = 47.3667, lon0 = 8.5450, r = 400.0 / (2 * .pi)
            while !Task.isCancelled {
                let along = Double(n) * speed
                let angle = along / r
                var lat = lat0 + r * sin(angle) / 111_195
                var lon = lon0 + r * (1 - cos(angle)) / (111_195 * cos(lat0 * .pi / 180))
                var acc = 5.0
                if n % 17 == 5 { acc = 45 }                       // too inaccurate: dropped
                if n % 29 == 11 { lat += 0.003; lon += 0.003 }    // a jump: dropped
                let p = TrackPoint(lat: lat, lon: lon, alt: 410 + 3 * sin(angle), t: t0 + Double(n), acc: acc, vacc: 4)
                self?.onPoints?([p])
                n += 1
                if n % 5 == 0 { try? await Task.sleep(for: .milliseconds(500)) }
            }
        }
    }

    func stop() {
        task?.cancel()
        task = nil
    }
}
#endif
