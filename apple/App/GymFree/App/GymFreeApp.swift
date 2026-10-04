import OpenGymCore
import SwiftUI

@main
struct GymFreeApp: App {
    @State private var store: GymStore
    @State private var catalog: ExerciseCatalog
    @State private var session: WorkoutSession
    @Environment(\.scenePhase) private var scenePhase

    init() {
        let storage: StateStorage = (try? FileStateStorage.standard())
            ?? FileStateStorage(url: URL.temporaryDirectory.appending(path: "gym_state_v1.json"))
        let store = GymStore(storage: storage)
        DebugLaunch.prepare(store, storage: storage)
        _store = State(initialValue: store)
        _catalog = State(initialValue: ExerciseCatalog(store: store))
        let session = WorkoutSession(store: store)
        session.syncSettings()
        _session = State(initialValue: session)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(catalog)
                .environment(session)
        }
        // Debounced saves cover normal use; leaving the app writes at once.
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { store.saveNow() }
        }
    }
}
