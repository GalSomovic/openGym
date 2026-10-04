import ActivityKit
import AlarmKit
import AppIntents
import SwiftUI
import WidgetKit

@main
struct GymFreeWidgets: WidgetBundle {
    var body: some Widget {
        WorkoutLiveActivity()
        RestAlarmActivity()
    }
}

private let lime = Color(red: 0.19, green: 0.82, blue: 0.35)

/// The workout on the Lock Screen: the exercise and set, the rest or hold counting down, and
/// buttons to tick the set or skip the rest without unlocking.
struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GymActivityAttributes.self) { ctx in
            LockScreenCard(state: ctx.state, name: ctx.attributes.workoutName)
                .padding()
                .activitySystemActionForegroundColor(lime)
        } dynamicIsland: { ctx in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "figure.strengthtraining.traditional").foregroundStyle(lime).font(.title2)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Countdown(state: ctx.state).font(.title2.weight(.bold).monospacedDigit())
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 2) {
                        Text(ctx.state.exercise).font(.headline).lineLimit(1)
                        Text(ctx.state.detail).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Actions(state: ctx.state).padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: ctx.state.resting ? "timer" : "figure.strengthtraining.traditional").foregroundStyle(lime)
            } compactTrailing: {
                if ctx.state.restEnd != nil || ctx.state.holdEnd != nil {
                    Countdown(state: ctx.state).monospacedDigit().frame(maxWidth: 44)
                } else {
                    Text("\(ctx.state.setsDone)/\(ctx.state.setsTotal)").monospacedDigit()
                }
            } minimal: {
                Image(systemName: "timer").foregroundStyle(lime)
            }
            .keylineTint(lime)
        }
    }
}

private struct Countdown: View {
    let state: GymActivityAttributes.ContentState

    var body: some View {
        if let s = state.holdStart, let e = state.holdEnd, e > s {
            Text(timerInterval: s...e, countsDown: true)
        } else if let s = state.restStart, let e = state.restEnd, e > s {
            Text(timerInterval: s...e, countsDown: true)
        } else {
            Text("\(state.setsDone)/\(state.setsTotal)")
        }
    }
}

private struct Actions: View {
    let state: GymActivityAttributes.ContentState

    var body: some View {
        HStack(spacing: 10) {
            if state.complete {
                Text("All sets done. Open GymFree to finish.").font(.footnote).foregroundStyle(.secondary)
            } else if state.resting {
                Button(intent: AddRestIntent()) { Label("+15 s", systemImage: "plus") }
                    .tint(.gray)
                Button(intent: SkipRestIntent()) { Label("Skip rest", systemImage: "forward.end.fill") }
                    .tint(lime)
            } else if state.holdEnd == nil {
                Button(intent: CompleteSetIntent()) {
                    Label("Set done", systemImage: "checkmark").frame(maxWidth: .infinity)
                }
                .tint(lime)
            }
        }
        .buttonStyle(.borderedProminent)
        .font(.subheadline.weight(.semibold))
    }
}

private struct LockScreenCard: View {
    let state: GymActivityAttributes.ContentState
    let name: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(state.resting ? "Rest · next up" : name).font(.caption).foregroundStyle(.secondary)
                    Text(state.exercise).font(.headline).lineLimit(1)
                    Text(state.detail).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                }
                Spacer()
                Countdown(state: state)
                    .font(.system(size: 34, weight: .bold).monospacedDigit())
                    .foregroundStyle(lime)
                    .frame(maxWidth: 120, alignment: .trailing)
            }
            ProgressView(value: Double(state.setsDone), total: Double(max(1, state.setsTotal)))
                .tint(lime)
            Actions(state: state)
        }
    }
}

/// AlarmKit's own Live Activity for the rest alarm. Apple requires an app that schedules
/// countdown alarms to render AlarmAttributes, or alarms may be dismissed without alerting.
struct RestAlarmActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<RestAlarmMetadata>.self) { ctx in
            HStack(spacing: 12) {
                Image(systemName: "timer").foregroundStyle(lime).font(.title2)
                VStack(alignment: .leading) {
                    Text(String(localized: ctx.attributes.presentation.alert.title)).font(.headline)
                    if let r = countdown(ctx) {
                        Text(timerInterval: r, countsDown: true).font(.title3.monospacedDigit()).foregroundStyle(lime)
                    }
                }
                Spacer()
            }
            .padding()
        } dynamicIsland: { ctx in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    Text(String(localized: ctx.attributes.presentation.alert.title)).font(.headline)
                }
            } compactLeading: {
                Image(systemName: "timer").foregroundStyle(lime)
            } compactTrailing: {
                if let r = countdown(ctx) { Text(timerInterval: r, countsDown: true).monospacedDigit().frame(maxWidth: 44) }
            } minimal: {
                Image(systemName: "timer").foregroundStyle(lime)
            }
        }
    }

    private func countdown(_ ctx: ActivityViewContext<AlarmAttributes<RestAlarmMetadata>>) -> ClosedRange<Date>? {
        guard case .countdown(let c) = ctx.state.mode, c.fireDate > c.startDate else { return nil }
        return c.startDate...c.fireDate
    }
}
