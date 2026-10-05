import Foundation
import OpenGymCore

/// Routes on the device, one file per activity, outside the profile: a long route is thousands
/// of points, and where you walk is nobody's business but yours. They are not part of backups
/// or any sync; the profile only records that a route exists (activity.js `route`).
///
/// The tracker also keeps a draft here while an activity is running, so one interrupted by the
/// app being closed can still be saved.
struct RouteStore: Sendable {
    let dir: URL

    static let standard: RouteStore = {
        let base = (try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true))
            ?? URL.temporaryDirectory
        return RouteStore(dir: base.appending(path: "Routes", directoryHint: .isDirectory))
    }()

    /// A saved route: stretches of points, split where the activity was paused.
    struct Route: Codable, Sendable {
        var kind: ActivityKind
        var segments: [[TrackPoint]]
    }

    /// The activity in progress.
    struct Draft: Codable, Sendable {
        var kind: ActivityKind
        var startedAt: Date
        /// Seconds moving, up to `savedAt`.
        var movingSec: Double
        var savedAt: Date
        var segments: [[TrackPoint]]

        var meters: Double { RouteMath.length(segments: segments) }
        /// When it last moved: the end it is saved with.
        var end: Date { segments.last?.last?.date ?? savedAt }
    }

    private func url(_ key: String) -> URL {
        // Workout ids are short base-36 strings; anything else is kept to safe characters.
        let safe = key.filter { $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" }
        return dir.appending(path: "\(safe).json")
    }

    private var draftURL: URL { dir.appending(path: "draft.json") }

    private func write<T: Encodable>(_ value: T, to url: URL) throws {
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try JSONEncoder().encode(value).write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    func save(_ route: Route, key: String) throws { try write(route, to: url(key)) }

    func load(_ key: String) -> Route? {
        guard let data = try? Data(contentsOf: url(key)) else { return nil }
        return try? JSONDecoder().decode(Route.self, from: data)
    }

    func delete(_ key: String) { try? FileManager.default.removeItem(at: url(key)) }

    func saveDraft(_ draft: Draft) { try? write(draft, to: draftURL) }

    func loadDraft() -> Draft? {
        guard let data = try? Data(contentsOf: draftURL) else { return nil }
        return try? JSONDecoder().decode(Draft.self, from: data)
    }

    func deleteDraft() { try? FileManager.default.removeItem(at: draftURL) }

    /// Route files whose workout is gone (deleted, or replaced by a restored backup).
    func prune(keeping keys: Set<String>) {
        guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return }
        for f in files where f.pathExtension == "json" && f.lastPathComponent != "draft.json" {
            if !keys.contains(f.deletingPathExtension().lastPathComponent) { try? FileManager.default.removeItem(at: f) }
        }
    }
}
