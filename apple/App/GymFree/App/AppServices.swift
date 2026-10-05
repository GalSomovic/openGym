import OpenGymCore
import SwiftUI

/// The app's long-lived objects, created once. A Lock Screen button can launch the app in the
/// background with no window, so the intents reach the same store and session through here.
@MainActor
final class AppServices {
    static let shared = AppServices()

    let store: GymStore
    let catalog: ExerciseCatalog
    let session: WorkoutSession
    let health: HealthSync
    let tracker: ActivityTracker

    private init() {
        let storage: StateStorage = (try? FileStateStorage.standard())
            ?? FileStateStorage(url: URL.temporaryDirectory.appending(path: "gym_state_v1.json"))
        store = GymStore(storage: storage)
        DebugLaunch.prepare(store, storage: storage)
        Fmt.sync(store)
        catalog = ExerciseCatalog(store: store)
        session = WorkoutSession(store: store, catalog: catalog)
        session.syncSettings()
        health = HealthSync()
        tracker = ActivityTracker(store: store, health: health)
        // Routes of activities no longer in the history (deleted, or a backup restored).
        RouteStore.standard.prune(keeping: Set(store.activityKeys()))
        GuidedBridge.handler = { [session] action in
            switch action {
            case .completeSet: session.completeCurrentSet()
            case .skipRest: session.stopRest()
            case .addRest: session.adjustRest(15)
            }
            session.saveSoon()
        }
        session.resumeIfActive()
        for _ in 0..<DebugLaunch.ticks { session.completeCurrentSet() }
    }
}
