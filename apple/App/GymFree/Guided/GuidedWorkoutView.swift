import OpenGymCore
import SwiftUI

/// Guided mode: one set at a time, full screen. The demo plays, the set's target is big, one
/// button ticks it, and the rest counts down with what comes next. Cues are spoken over your
/// music, which ducks for them and comes back up.
struct GuidedWorkoutView: View {
    let close: () -> Void
    let finish: () -> Void
    @Environment(GymStore.self) private var store
    @Environment(WorkoutSession.self) private var session
    @Environment(ExerciseCatalog.self) private var catalog
    @AppStorage(WorkoutSession.Pref.voice) private var voice = true

    var body: some View {
        let g = store.guide()
        NavigationStack {
            VStack(spacing: 0) {
                if let a = store.active {
                    ProgressView(value: Double(a.setsDone), total: Double(max(1, a.setsTotal)))
                        .tint(.accentColor)
                        .padding(.horizontal)
                }
                if let g, !g.done, let step = g.step {
                    if let r = session.rest {
                        RestPanel(rest: r, next: step, unit: g.unit)
                    } else {
                        StepPanel(step: step, next: g.next, unit: g.unit)
                    }
                } else {
                    DonePanel(finish: finish)
                }
            }
            .frame(maxWidth: 640)
            .frame(maxWidth: .infinity)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button { close() } label: { Image(systemName: "list.bullet") }
                        .accessibilityLabel(Text("Show the whole workout"))
                }
                ToolbarItem(placement: .principal) {
                    if let a = store.active {
                        TimelineView(.periodic(from: .now, by: 1)) { ctx in
                            Text(WorkoutView.elapsed(from: a.startDate, to: ctx.date))
                                .font(.subheadline.monospacedDigit()).foregroundStyle(.secondary)
                        }
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { voice.toggle(); session.syncSettings() } label: {
                        Image(systemName: voice ? "speaker.wave.2.fill" : "speaker.slash.fill")
                    }
                    .accessibilityLabel(Text(voice ? "Turn voice cues off" : "Turn voice cues on"))
                }
            }
        }
        .onAppear {
            session.guided = true
            UIApplication.shared.isIdleTimerDisabled = true
            session.announceStep()
        }
        .onDisappear {
            session.guided = false
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

/// The set to do now.
private struct StepPanel: View {
    let step: GuideStep
    let next: GuideStep?
    let unit: String
    /// Room for the demo, the numbers and the button on one screen.
    @State private var demoSize: CGFloat = 260
    @Environment(GymStore.self) private var store
    @Environment(WorkoutSession.self) private var session
    @Environment(ExerciseCatalog.self) private var catalog

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                ExerciseAnimation(exerciseId: step.exerciseId, toggle: true)
                    .frame(maxWidth: 360, maxHeight: demoSize)
                    .clipShape(.rect(cornerRadius: 22))
                    .padding(.top, 4)
                    .overlay(alignment: .bottomTrailing) {
                        Text("© AscendAPI").font(.system(size: 9)).foregroundStyle(.black.opacity(0.35)).padding(6)
                    }
                VStack(spacing: 6) {
                    Text(catalog.name(step.exerciseId))
                        .font(.title2.weight(.bold)).multilineTextAlignment(.center)
                    HStack(spacing: 8) {
                        Text(step.warm ? "Warm-up \(step.num) of \(step.count)" : "Set \(step.num) of \(step.count)")
                        if let side = step.side { Text(side == "L" ? "· Left" : "· Right") }
                        if step.superset == true { Label("Superset", systemImage: "link").labelStyle(.titleAndIcon) }
                    }
                    .font(.headline)
                    .foregroundStyle(step.warm ? Color.orange : .secondary)
                }
                targets
                if let h = session.hold, h.entry == step.idx, h.set == step.set {
                    HoldPanel(hold: h)
                } else {
                    Button { session.completeCurrentSet() } label: {
                        Label(step.timed ? "Start hold" : "Set done", systemImage: step.timed ? "play.fill" : "checkmark")
                            .font(.title3.weight(.bold))
                            .frame(maxWidth: .infinity, minHeight: 60)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.roundedRectangle(radius: 20))
                    .padding(.horizontal)
                    .sensoryFeedback(.success, trigger: store.active?.setsDone ?? 0) { _, _ in session.haptics }
                }
                if let next {
                    UpNext(step: next, unit: unit).padding(.horizontal)
                }
            }
            .padding(.bottom, 24)
        }
        .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { h in
            demoSize = max(140, min(320, h * 0.34))
        }
    }

    /// The numbers for this set, adjustable before ticking it.
    @ViewBuilder
    private var targets: some View {
        let unitLabel = unit
        HStack(spacing: 14) {
            if step.cardio {
                BigValue(value: step.min ?? 0, label: "min", decimals: 0) { bump("min", $0) }
            } else if step.timed {
                BigValue(value: step.sec ?? 0, label: "sec", decimals: 0) { bump("sec", $0) }
                if !step.bw || (step.w ?? 0) > 0 {
                    BigValue(value: step.w ?? 0, label: unitLabel, decimals: 2) { bump("w", $0) }
                }
            } else {
                if !step.bw || (step.w ?? 0) > 0 {
                    BigValue(value: step.w ?? 0, label: unitLabel, decimals: 2) { bump("w", $0) }
                }
                BigValue(value: step.r ?? 0, label: String(localized: "reps"), decimals: 0) { bump("r", $0) }
            }
        }
        .padding(.horizontal)
    }

    private func bump(_ field: String, _ dir: Int) {
        store.bump(step.idx, step.set, field, dir, side: step.side)
        session.publish()
    }
}

/// A big number with − and + under it.
private struct BigValue: View {
    let value: Double
    let label: String
    let decimals: Int
    let step: (Int) -> Void

    var body: some View {
        VStack(spacing: 6) {
            Text(Fmt.num(value, decimals: decimals))
                .font(.system(size: 46, weight: .bold, design: .rounded).monospacedDigit())
                .contentTransition(.numericText(value: value))
                .minimumScaleFactor(0.5).lineLimit(1)
            Text(label).font(.subheadline).foregroundStyle(.secondary)
            HStack(spacing: 18) {
                Button { step(-1) } label: { Image(systemName: "minus").frame(width: 44, height: 36) }
                    .accessibilityLabel(Text("Decrease \(label)"))
                Button { step(1) } label: { Image(systemName: "plus").frame(width: 44, height: 36) }
                    .accessibilityLabel(Text("Increase \(label)"))
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(.background.secondary, in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text("\(Fmt.num(value, decimals: decimals)) \(label)"))
    }
}

/// A timed hold counting down.
private struct HoldPanel: View {
    let hold: WorkoutSession.Hold
    @Environment(WorkoutSession.self) private var session

    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.1)) { ctx in
            let left = max(0, hold.endsAt.timeIntervalSince(ctx.date))
            VStack(spacing: 14) {
                Ring(fraction: left / hold.plan, text: TimerBar.holdClock(hold, now: ctx.date), caption: String(localized: "Hold"))
                    .frame(width: 200, height: 200)
                Button { session.finishHoldEarly() } label: {
                    Text("Done").font(.title3.weight(.bold)).frame(maxWidth: .infinity, minHeight: 54)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 18))
                .padding(.horizontal)
            }
        }
    }
}

/// The rest, with what comes after it.
private struct RestPanel: View {
    let rest: WorkoutSession.Rest
    let next: GuideStep
    let unit: String
    @Environment(WorkoutSession.self) private var session
    @Environment(GymStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                TimelineView(.periodic(from: .now, by: 0.1)) { ctx in
                    let left = rest.remaining(at: ctx.date)
                    Ring(fraction: rest.total > 0 ? left / rest.total : 0,
                         text: rest.ready ? String(localized: "Go!") : TimerBar.clock(left),
                         caption: rest.ready ? String(localized: "Rest over") : rest.paused != nil ? String(localized: "Paused") : String(localized: "Rest"))
                        .frame(width: 240, height: 240)
                        .padding(.top, 24)
                }
                if !rest.ready {
                    HStack(spacing: 12) {
                        Button("−15 s") { session.adjustRest(-15) }
                        Button { session.togglePause() } label: {
                            Image(systemName: rest.paused != nil ? "play.fill" : "pause.fill").frame(width: 30)
                        }
                        .accessibilityLabel(Text(rest.paused != nil ? "Resume" : "Pause"))
                        Button("+15 s") { session.adjustRest(15) }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
                Button { session.stopRest() } label: {
                    Text(rest.ready ? "Next set" : "Skip rest").font(.title3.weight(.bold)).frame(maxWidth: .infinity, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 18))
                .padding(.horizontal)
                UpNext(step: next, unit: unit, title: "Up next").padding(.horizontal)
                EffortQuickRate()
            }
            .padding(.bottom, 24)
        }
    }
}

/// During a rest: how hard was the set just done? (Only when the profile logs effort.)
private struct EffortQuickRate: View {
    @Environment(GymStore.self) private var store

    var body: some View {
        if let kind = store.pick("effort", as: String.self), kind == "rir" || kind == "rpe",
           let (idx, set, side) = lastDone() {
            VStack(spacing: 8) {
                Text("How hard was that set?").font(.subheadline.weight(.semibold))
                HStack(spacing: 8) {
                    ForEach([0.0, 1, 2, 3, 4], id: \.self) { rir in
                        let v = kind == "rpe" ? 10 - rir : rir
                        Button {
                            if let side { store.setSideValue(idx, set, side, kind, v) } else { store.setTyped(idx, set, kind, v) }
                        } label: {
                            Text(rir == 4 ? "\(Fmt.num(v))\(kind == "rir" ? "+" : "")" : Fmt.num(v))
                                .font(.headline.monospacedDigit()).frame(width: 46, height: 40)
                        }
                        .buttonStyle(.bordered)
                        .tint(EffortCell.color(rir: rir))
                    }
                }
                Text(kind == "rir" ? "Reps left in the tank" : "RPE").font(.caption).foregroundStyle(.secondary)
            }
            .padding()
            .background(.background.secondary, in: .rect(cornerRadius: 18))
            .padding(.horizontal)
        }
    }

    /// The set the rest belongs to: the last ticked row of the exercise that earned it.
    private func lastDone() -> (Int, Int, String?)? {
        guard let a = store.active else { return nil }
        for (i, e) in a.entries.enumerated().reversed() {
            if let s = e.sets.lastIndex(where: { $0.isDone || $0.sides?.values.contains { $0.done == true } == true }) {
                let row = e.sets[s]
                let side: String? = row.isPerSide ? (row.sides?["R"]?.done == true ? "R" : "L") : nil
                if row.isWarmup { return nil }
                return (i, s, side)
            }
        }
        return nil
    }
}

private struct UpNext: View {
    let step: GuideStep
    let unit: String
    var title: LocalizedStringKey = "Then"
    @Environment(ExerciseCatalog.self) private var catalog

    var body: some View {
        HStack(spacing: 12) {
            ExerciseThumb(exerciseId: step.exerciseId, size: 56)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary).textCase(.uppercase)
                Text(catalog.name(step.exerciseId)).font(.headline).lineLimit(2)
                Text("\(step.warm ? String(localized: "Warm-up \(step.num) of \(step.count)") : String(localized: "Set \(step.num) of \(step.count)")) · \(WorkoutSession.shortTarget(step, unit: unit))")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.background.secondary, in: .rect(cornerRadius: 18))
    }
}

private struct DonePanel: View {
    let finish: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: "checkmark.seal.fill").font(.system(size: 80)).foregroundStyle(Color.accentColor)
                .symbolEffect(.bounce, options: .nonRepeating)
            Text("All sets done").font(.largeTitle.weight(.bold))
            Text("Finish to save the workout and see your records.").foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button(action: finish) {
                Text("Finish workout").font(.title3.weight(.bold)).frame(maxWidth: .infinity, minHeight: 56)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 18))
            Spacer()
        }
        .padding()
    }
}

/// A countdown ring with the time in the middle.
struct Ring: View {
    let fraction: Double
    let text: String
    let caption: String

    var body: some View {
        ZStack {
            Circle().stroke(.quaternary, lineWidth: 14)
            Circle().trim(from: 0, to: max(0, min(1, fraction)))
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: fraction)
            VStack(spacing: 2) {
                Text(text).font(.system(size: 56, weight: .bold, design: .rounded).monospacedDigit())
                    .contentTransition(.numericText(countsDown: true))
                Text(caption).font(.headline).foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("\(caption), \(text)"))
    }
}
