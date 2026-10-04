import Foundation
import OpenGymCore

/// Debug-only launch arguments that open a screen directly, for screenshots and UI checks:
///   -GFReset YES        start from an empty profile
///   -GFStarter ppl      load a starter plan into an empty profile
///   -GFTab exercises    today | plan | exercises | settings
///   -GFDetail 0025      open an exercise in the library
///   -GFRoutine 0        open the n-th routine in the plan
///   -GFStart 0          start the n-th routine
enum DebugLaunch {
    #if DEBUG
    private static var args: UserDefaults { .standard }
    static var tab: AppTab? {
        switch args.string(forKey: "GFTab") {
        case "today": .today
        case "plan": .plan
        case "exercises": .exercises
        case "settings": .settings
        default: nil
        }
    }
    static var detail: String? { args.string(forKey: "GFDetail") }
    static var routine: Int? { args.object(forKey: "GFRoutine").map { _ in args.integer(forKey: "GFRoutine") } }
    /// -GFConfig 0: with -GFRoutine, open that routine's n-th exercise settings.
    static var config: Int? { args.object(forKey: "GFConfig").map { _ in args.integer(forKey: "GFConfig") } }

    @MainActor
    static func prepare(_ store: GymStore, storage: StateStorage) {
        if args.bool(forKey: "GFReset") { try? store.replaceProfile(json: "{}") }
        if let plan = args.string(forKey: "GFStarter"), store.routines.isEmpty { store.loadStarterPlan(plan) }
        if args.object(forKey: "GFStart") != nil, store.active == nil {
            let i = args.integer(forKey: "GFStart")
            if i < store.routines.count {
                store.beginWorkout(routineIds: [store.routines[i].id], bodyWeight: nil, freestyleName: "Freestyle")
            }
        }
    }
    #else
    static let tab: AppTab? = nil
    static let detail: String? = nil
    static let routine: Int? = nil
    static let config: Int? = nil
    @MainActor static func prepare(_ store: GymStore, storage: StateStorage) {}
    #endif
}
