import OpenGymCore
import SwiftUI

/// The rest countdown (or a timed hold) pinned above the tab bar.
struct TimerBar: View {
    @Environment(WorkoutSession.self) private var session
    @Environment(GymStore.self) private var store
    @Environment(ExerciseCatalog.self) private var catalog

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.25)) { ctx in
            if let h = session.hold {
                hold(h, now: ctx.date)
            } else if let r = session.rest {
                rest(r, now: ctx.date)
            }
        }
        .padding(12)
        .glassEffect(in: .rect(cornerRadius: 22))
    }

    private func rest(_ r: WorkoutSession.Rest, now: Date) -> some View {
        let left = r.remaining(at: now)
        return HStack(spacing: 12) {
            ZStack {
                Circle().stroke(.quaternary, lineWidth: 5)
                Circle().trim(from: 0, to: r.total > 0 ? left / r.total : 0)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 40, height: 40)
            VStack(alignment: .leading, spacing: 0) {
                Text(r.ready ? "Ready" : r.paused != nil ? "Paused" : "Rest").font(.caption).foregroundStyle(.secondary)
                Text(r.ready ? "Go!" : Self.clock(left)).font(.title2.weight(.bold).monospacedDigit())
                    .contentTransition(.numericText(countsDown: true))
            }
            Spacer()
            if !r.ready {
                Button { session.adjustRest(-15) } label: { Text("−15") }.buttonStyle(.bordered)
                Button { session.adjustRest(15) } label: { Text("+15") }.buttonStyle(.bordered)
                Button { session.togglePause() } label: { Image(systemName: r.paused != nil ? "play.fill" : "pause.fill") }
                    .buttonStyle(.bordered)
                    .accessibilityLabel(Text(r.paused != nil ? "Resume" : "Pause"))
            }
            Button { session.stopRest() } label: { Image(systemName: r.ready ? "checkmark" : "forward.end.fill") }
                .buttonStyle(.borderedProminent)
                .accessibilityLabel(Text(r.ready ? "Dismiss" : "Skip rest"))
        }
        .controlSize(.small)
    }

    private func hold(_ h: WorkoutSession.Hold, now: Date) -> some View {
        let name = store.active?.entries[safe: h.entry].map { catalog.name($0.id) } ?? ""
        return HStack(spacing: 12) {
            Image(systemName: "timer").font(.title2).foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 0) {
                Text(name).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                Text(Self.holdClock(h, now: now)).font(.title2.weight(.bold).monospacedDigit())
            }
            Spacer()
            Button("Cancel") { session.cancelHold() }.buttonStyle(.bordered)
            Button("Done") { session.finishHoldEarly() }.buttonStyle(.borderedProminent)
        }
        .controlSize(.small)
    }

    /// A hold counts down to its target, then (openGym's "Keep timing after target") up past it.
    static func holdClock(_ h: WorkoutSession.Hold, now: Date) -> String {
        let over = now.timeIntervalSince(h.endsAt)
        return h.overtime && over > 0 ? "+" + clock(over.rounded(.down)) : clock(max(0, -over))
    }

    static func clock(_ seconds: Double) -> String {
        let s = Int(seconds.rounded(.up))
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
