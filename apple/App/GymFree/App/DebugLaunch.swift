import Foundation
import OpenGymCore

/// Debug-only launch arguments that open a screen directly, for screenshots and UI checks:
///   -GFReset YES        start from an empty profile
///   -GFStarter ppl      load a starter plan into an empty profile
///   -GFEquipment none   bodyweight only (or a comma-separated list)
///   -GFTab exercises    today | plan | stats | exercises | settings
///   -GFSeed 6           log that many past workouts of the first routine, a few days apart,
///                       each heavier and rated (RIR), for the Stats screens
///   -GFProgress 0025    with -GFTab stats, open that exercise's progress
///   -GFBalance YES      with -GFTab stats, open structural balance
///   -GFDetail 0025      open an exercise in the library
///   -GFRoutine 0        open the n-th routine in the plan
///   -GFStart 0          start the n-th routine
///   -GFBackupFile YES   Settings → Data exports to and imports from a file in the app's tmp
///                       folder instead of the system file sheets (UI tests cannot drive those)
///   GFImportText (environment): the text "Import from another app" reads instead of a file
enum DebugLaunch {
    #if DEBUG
    private static var args: UserDefaults { .standard }
    static var tab: AppTab? {
        switch args.string(forKey: "GFTab") {
        case "today": .today
        case "plan": .plan
        case "stats": .stats
        case "exercises": .exercises
        case "settings": .settings
        default: nil
        }
    }
    static var detail: String? { args.string(forKey: "GFDetail") }
    @MainActor static var statsPath: [TodayRouter.Route] {
        if let id = args.string(forKey: "GFProgress") { return [.progress(id)] }
        if args.bool(forKey: "GFBalance") { return [.balance] }
        return []
    }
    static var routine: Int? { args.object(forKey: "GFRoutine").map { _ in args.integer(forKey: "GFRoutine") } }
    /// -GFGuided YES: open guided mode on the running workout.
    static var guided: Bool { args.bool(forKey: "GFGuided") }
    /// -GFTick 1: complete that many sets the way guided mode does.
    static var ticks: Int { args.integer(forKey: "GFTick") }
    /// -GFConfig 0: with -GFRoutine, open that routine's n-th exercise settings.
    static var config: Int? { args.object(forKey: "GFConfig").map { _ in args.integer(forKey: "GFConfig") } }
    static var backupFile: URL? {
        args.bool(forKey: "GFBackupFile") ? URL.temporaryDirectory.appending(path: "gymfree-uitest-backup.json") : nil
    }
    static var importText: String? { ProcessInfo.processInfo.environment["GFImportText"] }

    @MainActor
    static func prepare(_ store: GymStore, storage: StateStorage) {
        if args.bool(forKey: "GFReset") { try? store.replaceProfile(json: "{}") }
        if let eq = args.string(forKey: "GFEquipment") {
            store.setEquipment(eq == "none" ? [] : eq.components(separatedBy: ","), name: "My equipment")
        }
        if let plan = args.string(forKey: "GFStarter"), store.routines.isEmpty { store.loadStarterPlan(plan) }
        if args.integer(forKey: "GFSeed") > 0, store.workouts.isEmpty, let routine = store.routines.first {
            seed(store, routine: routine.id, count: args.integer(forKey: "GFSeed"))
        }
        if args.object(forKey: "GFStart") != nil, store.active == nil {
            let i = args.integer(forKey: "GFStart")
            if i < store.routines.count {
                store.beginWorkout(routineIds: [store.routines[i].id], bodyWeight: nil, freestyleName: "Freestyle")
            }
        }
    }

    /// Past workouts of `routine`, three days apart up to yesterday, each 2.5 heavier than the
    /// last and rated, logged through the same actions as "Log a past workout".
    @MainActor private static func seed(_ store: GymStore, routine: String, count: Int) {
        store.setEffort("rir")
        let cal = Calendar.current
        // Each set's first weight, so the climb is 2.5 a session on top of it, not compounded
        // with the progression the engine applies after every finish.
        var base: [String: Double] = [:]
        for i in 0..<count {
            guard let day = cal.date(byAdding: .day, value: -3 * (count - i), to: .now) else { continue }
            store.beginBackfill(iso: Fmt.todayISO(day), time: "18:00", durationMin: 40 + 5 * (i % 4),
                                routineIds: [routine], replaceId: nil, freestyleName: "Freestyle")
            guard let active = store.active else { continue }
            for (e, entry) in active.entries.enumerated() {
                for (s, row) in entry.sets.enumerated() {
                    // Starter plans leave the weight to you: a rep set gets 20 to start from.
                    if row.r != nil {
                        let start = base["\(e).\(s)", default: max(row.w ?? 0, 20)]
                        base["\(e).\(s)"] = start
                        store.setField(e, s, "w", start + 2.5 * Double(i))
                    }
                    store.setField(e, s, "rir", Double((count - i + s) % 4))
                }
            }
            store.markAllDone()
            store.finishWorkout()
        }
    }
    #else
    static let tab: AppTab? = nil
    @MainActor static var statsPath: [TodayRouter.Route] { [] }
    static let detail: String? = nil
    static let routine: Int? = nil
    static let config: Int? = nil
    static let guided = false
    static let ticks = 0
    static let backupFile: URL? = nil
    static let importText: String? = nil
    @MainActor static func prepare(_ store: GymStore, storage: StateStorage) {}
    #endif
}
