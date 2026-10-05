import OpenGymCore
import SwiftUI

@main
struct GymFreeApp: App {
    @UIApplicationDelegateAdaptor(OrientationLock.self) private var orientation
    @Environment(\.scenePhase) private var scenePhase
    private let services = AppServices.shared

    init() {
        // Before any demo video plays: the default audio mode would stop the user's music.
        CuePlayer.mixWithMusic()
    }

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

/// The app is portrait on iPhone; a demo shown full screen may turn to landscape.
final class OrientationLock: NSObject, UIApplicationDelegate {
    @MainActor static var allowsLandscape = false {
        didSet { apply() }
    }

    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        MainActor.assumeIsolated {
            Self.allowsLandscape || UIDevice.current.userInterfaceIdiom == .pad ? .allButUpsideDown : .portrait
        }
    }

    /// Turns to landscape, as a full-screen video does; the phone can still be turned back.
    @MainActor static func turnToLandscape() {
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscapeRight))
        }
    }

    @MainActor private static func apply() {
        for case let scene as UIWindowScene in UIApplication.shared.connectedScenes {
            // The topmost presented controller (the full-screen cover) is the one iOS asks.
            var top = scene.keyWindow?.rootViewController
            while let next = top?.presentedViewController { top = next }
            top?.setNeedsUpdateOfSupportedInterfaceOrientations()
            scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
            if !allowsLandscape, UIDevice.current.userInterfaceIdiom == .phone {
                scene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
            }
        }
    }
}
