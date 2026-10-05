import ActivityKit
import Foundation

/// Keeps the walk's Live Activity in step with the tracker: started with the activity, updated
/// every few seconds, ended when it is saved or thrown away.
@MainActor
final class MotionLiveActivityController {
    private var activity: Activity<MotionActivityAttributes>?

    func update(kind: String, name: String, startedAt: Date, state: MotionActivityAttributes.ContentState) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        let content = ActivityContent(state: state, staleDate: nil)
        if let activity, activity.activityState == .active {
            Task { await activity.update(content) }
            return
        }
        let attributes = MotionActivityAttributes(kind: kind, name: name, startedAt: startedAt)
        activity = try? Activity.request(attributes: attributes, content: content, pushType: nil)
    }

    func end() {
        activity = nil
        endLeftovers()
    }

    /// One left over from an activity that ended while the app was gone.
    func endLeftovers() {
        for a in Activity<MotionActivityAttributes>.activities { Task { await a.end(nil, dismissalPolicy: .immediate) } }
    }
}
