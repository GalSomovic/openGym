import Observation
import OpenGymCore

/// The exercise catalogue, read from the engine once and kept for every screen that names an
/// exercise. Searches go to the engine and come back as ids into it.
@MainActor
@Observable
final class ExerciseCatalog {
    private(set) var all: [ExerciseBrief] = []
    private(set) var bodyParts: [String] = []
    private(set) var muscleNames: [String: String] = [:]
    @ObservationIgnored private var byId: [String: ExerciseBrief] = [:]
    @ObservationIgnored private let store: GymStore

    init(store: GymStore) {
        self.store = store
        reload()
    }

    /// Again after custom exercises change.
    func reload() {
        all = store.catalogue()
        byId = Dictionary(all.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        bodyParts = store.bodyParts()
        muscleNames = (try? Engine.shared.value("muscles", "MUSCLE_NAME", as: [String: String].self)) ?? [:]
    }

    subscript(id: String) -> ExerciseBrief? { byId[id] }

    func name(_ id: String) -> String { byId[id]?.displayName ?? id }

    /// "chest · barbell": the target muscle (or body part) and the equipment.
    func subtitle(_ e: ExerciseBrief) -> String {
        let muscle = e.tg.flatMap { muscleNames[$0] ?? $0 } ?? e.bp
        return [muscle, e.eq].compactMap { $0 }.map(\.capitalizedWords).joined(separator: " · ")
    }

    func muscleName(_ key: String) -> String { (muscleNames[key] ?? key).capitalizedWords }
}
