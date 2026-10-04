import OpenGymCore
import SwiftUI

@main
struct GymFreeApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let services = AppServices.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(services.store)
                .environment(services.catalog)
                .environment(services.session)
        }
        // Debounced saves cover normal use; leaving the app writes at once.
        .onChange(of: scenePhase) { _, phase in
            if phase != .active { services.store.saveNow() }
            if phase == .active { services.session.syncSettings() }
        }
    }
}
