import ActivityKit
import Foundation

/// Keeps the workout's Live Activity in step with the session. One activity per workout,
/// started with it and ended when it is finished or discarded.
@MainActor
final class LiveActivityController {
    private var activity: Activity<GymActivityAttributes>?
    private var workoutId: String?

    func update(workoutId: String, name: String, startedAt: Date, state: GymActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let content = ActivityContent(state: state, staleDate: nil)
        if let activity, self.workoutId == workoutId, activity.activityState == .active {
            Task { await activity.update(content) }
            return
        }
        // A leftover from a session that ended while the app was gone.
        for old in Activity<GymActivityAttributes>.activities { Task { await old.end(nil, dismissalPolicy: .immediate) } }
        let attributes = GymActivityAttributes(workoutName: name, startedAt: startedAt)
        activity = try? Activity.request(attributes: attributes, content: content, pushType: nil)
        self.workoutId = workoutId
    }

    func end() {
        let all = Activity<GymActivityAttributes>.activities
        activity = nil
        workoutId = nil
        for a in all { Task { await a.end(nil, dismissalPolicy: .immediate) } }
    }
}
