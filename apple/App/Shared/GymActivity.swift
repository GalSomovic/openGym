import ActivityKit
import AlarmKit
import AppIntents
import Foundation

/// The running workout on the Lock Screen and in the Dynamic Island.
struct GymActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// The exercise being done, or coming up after the rest.
        var exercise: String
        /// "Set 2 of 4 · 60 kg × 8".
        var detail: String
        var restStart: Date?
        var restEnd: Date?
        var holdStart: Date?
        var holdEnd: Date?
        var setsDone: Int
        var setsTotal: Int
        /// Every set done: the card offers Finish in the app.
        var complete: Bool

        var resting: Bool { restEnd.map { $0 > .now } ?? false }
    }

    var workoutName: String
    var startedAt: Date
}

/// The rest alarm that rings through silent mode (AlarmKit), opt-in.
struct RestAlarmMetadata: AlarmMetadata {}

/// What the Lock Screen buttons ask the app to do. The intents run in the app's process
/// (LiveActivityIntent); the app installs the handler when it starts.
enum GuidedAction: String, Sendable {
    case completeSet, skipRest, addRest
}

@MainActor
enum GuidedBridge {
    static var handler: ((GuidedAction) -> Void)?
}

struct CompleteSetIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Set done"
    static let description = IntentDescription("Ticks off the current set and starts the rest.")

    func perform() async throws -> some IntentResult {
        await MainActor.run { GuidedBridge.handler?(.completeSet) }
        return .result()
    }
}

struct SkipRestIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Skip rest"

    func perform() async throws -> some IntentResult {
        await MainActor.run { GuidedBridge.handler?(.skipRest) }
        return .result()
    }
}

struct AddRestIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Add 15 seconds of rest"

    func perform() async throws -> some IntentResult {
        await MainActor.run { GuidedBridge.handler?(.addRest) }
        return .result()
    }
}
