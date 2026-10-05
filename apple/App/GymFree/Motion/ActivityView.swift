import MapKit
import OpenGymCore
import SwiftUI

/// Walk, run or ride with GPS: pick what, start, and watch the route grow with the distance,
/// moving time and pace; pause, resume, finish. Closing the screen keeps tracking (Today shows
/// it in progress), and so does locking the phone.
struct ActivityView: View {
    @Environment(ActivityTracker.self) private var tracker
    @Environment(GymStore.self) private var store
    @Environment(HealthSync.self) private var health
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var camera: MapCameraPosition = .automatic
    @State private var askFinish = false
    @State private var askDiscard = false
    @AppStorage("gf.activityKind") private var lastKind = ActivityKind.walk.rawValue

    var body: some View {
        NavigationStack {
            Group {
                if let f = tracker.finished {
                    ActivitySummaryView(finished: f, format: store.motionFormat, toHealth: health.writesWorkouts) {
                        tracker.closeSummary()
                        dismiss()
                    }
                } else {
                    tracking
                }
            }
        }
        .onAppear {
            if tracker.phase == .idle, let k = ActivityKind(rawValue: lastKind) { tracker.choose(k) }
            tracker.prepare()
        }
        .onDisappear { tracker.unprepare() }
    }

    /* ------------------------------ tracking ------------------------------ */

    private var tracking: some View {
        VStack(spacing: 0) {
            map
                .overlay(alignment: .top) { gpsBadge.padding(.top, 8) }
                .overlay(alignment: .bottomTrailing) {
                    Button { follow(animated: true) } label: {
                        Image(systemName: camera.positionedByUser ? "location" : "location.fill")
                            .padding(10)
                            .background(.regularMaterial, in: .circle)
                    }
                    .padding(10)
                    .accessibilityLabel(Text("Center on my position"))
                }
            panel
        }
        .navigationTitle(tracker.kind.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button { dismiss() } label: { Image(systemName: tracker.isActive ? "chevron.down" : "xmark") }
                    .accessibilityLabel(tracker.isActive ? Text("Minimize") : Text("Close"))
                    .accessibilityIdentifier("activity.close")
            }
            if tracker.isActive {
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .destructive) { askDiscard = true } label: { Image(systemName: "trash") }
                        .accessibilityLabel(Text("Discard \(tracker.kind.title.lowercased())"))
                        .accessibilityIdentifier("activity.discard")
                }
            }
        }
        .confirmationDialog("Finish \(tracker.kind.title.lowercased())?", isPresented: $askFinish, titleVisibility: .visible) {
            Button("Save") { tracker.finish() }
                .accessibilityIdentifier("activity.save")
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("It goes into your history\(health.writesWorkouts ? String(localized: " and Apple Health") : "").")
        }
        .confirmationDialog("Discard \(tracker.kind.title.lowercased())?", isPresented: $askDiscard, titleVisibility: .visible) {
            Button("Discard", role: .destructive) { tracker.discard(); dismiss() }
        } message: {
            Text("Nothing of it is saved.")
        }
        .onChange(of: tracker.lastFix) { _, _ in if !camera.positionedByUser { follow() } }
    }

    private var map: some View {
        Map(position: $camera) {
            RouteLines(segments: tracker.segments)
            if let p = tracker.lastFix {
                Annotation("", coordinate: p.coordinate, anchor: .center) {
                    ZStack {
                        Circle().fill(Color.accentColor.opacity(0.18)).frame(width: 34, height: 34)
                        Circle().fill(Color.accentColor).stroke(.white, lineWidth: 3).frame(width: 16, height: 16)
                    }
                }
                .annotationTitles(.hidden)
            }
        }
        .mapStyle(.standard(elevation: .flat, pointsOfInterest: .excludingAll))
        .mapControls { MapCompass(); MapScaleView() }
        .accessibilityIdentifier("activity.map")
    }

    /// Keeps the position in view; animated only when asked, not on every fix.
    private func follow(animated: Bool = false) {
        guard let p = tracker.lastFix else { camera = .automatic; return }
        let next = MapCameraPosition.camera(MapCamera(centerCoordinate: p.coordinate, distance: tracker.kind == .cycle ? 1600 : 800))
        if animated { withAnimation(.easeInOut(duration: 0.4)) { camera = next } } else { camera = next }
    }

    /// GPS quality before and during tracking; the permission when it is missing.
    @ViewBuilder
    private var gpsBadge: some View {
        let (text, color): (LocalizedStringKey, Color) = {
            switch tracker.permission {
            case .denied, .restricted: return ("Location is off", .red)
            case .approximate: return ("Precise location is off", .orange)
            case .notAsked: return ("Waiting for permission", .secondary)
            case .allowed:
                guard let acc = tracker.lastFix?.acc, acc >= 0 else { return ("Finding GPS…", .secondary) }
                if acc <= 10 { return ("GPS good", .green) }
                if acc <= 20 { return ("GPS fair", .orange) }
                return ("GPS weak", .red)
            }
        }()
        Label { Text(text) } icon: { Image(systemName: "location.fill").foregroundStyle(color) }
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 12).padding(.vertical, 6)
            .background(.regularMaterial, in: .capsule)
            .accessibilityIdentifier("activity.gps")
    }

    /* ------------------------------ numbers and buttons ------------------------------ */

    private var panel: some View {
        let f = store.motionFormat
        return VStack(spacing: 14) {
            TimelineView(.periodic(from: .now, by: 1)) { ctx in
                let moving = tracker.movingSeconds(at: ctx.date)
                VStack(spacing: 10) {
                    VStack(spacing: 0) {
                        Text(f.distance(tracker.meters))
                            .font(.system(size: 56, weight: .bold, design: .rounded).monospacedDigit())
                            .contentTransition(.numericText())
                            .accessibilityIdentifier("activity.distance")
                        Text(f.imperial ? "miles" : "kilometres").font(.subheadline).foregroundStyle(.secondary)
                    }
                    HStack {
                        stat(MotionFormat.clock(moving), tracker.phase == .paused ? "Paused" : "Time")
                        if tracker.kind == .cycle {
                            stat(f.speed(kmh: RouteMath.speedKmh(seconds: moving, meters: tracker.meters)), "Avg \(f.speedUnit)")
                        } else {
                            stat(f.pace(RouteMath.pace(seconds: moving, meters: tracker.meters, perMeters: f.perMeters)), "Avg pace /\(f.distanceUnit)")
                            stat(f.pace(tracker.currentPace(perMeters: f.perMeters)), "Pace /\(f.distanceUnit)")
                        }
                    }
                }
            }
            controls
        }
        .padding()
        .background(.background)
    }

    private func stat(_ value: String, _ label: LocalizedStringKey) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title2.weight(.semibold).monospacedDigit()).lineLimit(1).minimumScaleFactor(0.6)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var controls: some View {
        switch tracker.phase {
        case .idle:
            VStack(spacing: 12) {
                Picker("Activity", selection: Binding(get: { tracker.kind }, set: { tracker.choose($0); lastKind = $0.rawValue })) {
                    ForEach(ActivityKind.allCases) { k in Label(k.title, systemImage: k.symbol).tag(k) }
                }
                .pickerStyle(.segmented)
                if tracker.permission == .denied || tracker.permission == .restricted {
                    Text("GymFree needs your location to draw the route and measure the distance. Turn it on in Settings → Privacy & Security → Location Services → GymFree.")
                        .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Button("Open Settings") { if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) } }
                        .buttonStyle(.bordered)
                } else {
                    Button { tracker.start() } label: {
                        Label("Start \(tracker.kind.title.lowercased())", systemImage: "play.fill")
                            .frame(maxWidth: .infinity).fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityIdentifier("activity.start")
                    if tracker.permission == .approximate {
                        Text("Precise Location is off, so the route will be rough. Turn it on in Settings → GymFree → Location.")
                            .font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                }
            }
        case .running, .paused:
            HStack(spacing: 12) {
                if tracker.phase == .running {
                    Button { tracker.pause() } label: {
                        Label("Pause", systemImage: "pause.fill").frame(maxWidth: .infinity).fontWeight(.semibold)
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("activity.pause")
                } else {
                    Button { tracker.resume() } label: {
                        Label("Resume", systemImage: "play.fill").frame(maxWidth: .infinity).fontWeight(.semibold)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("activity.resume")
                }
                Button { askFinish = true } label: {
                    Label("Finish", systemImage: "stop.fill").frame(maxWidth: .infinity).fontWeight(.semibold)
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .accessibilityIdentifier("activity.finish")
            }
            .controlSize(.large)
        }
    }
}

/// What was just saved: the route, distance, time and pace.
struct ActivitySummaryView: View {
    let finished: ActivityTracker.Finished
    let format: MotionFormat
    let toHealth: Bool
    let close: () -> Void

    var body: some View {
        let f = format
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(Color.accentColor)
                    .padding(.top, 20)
                Text("\(finished.kind.title) saved").font(.largeTitle.weight(.bold))
                    .accessibilityIdentifier("activity.saved")
                if finished.segments.contains(where: { $0.count > 1 }) {
                    RouteMapView(segments: finished.segments)
                        .frame(height: 260)
                        .clipShape(.rect(cornerRadius: 16))
                }
                Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        tile("\(f.distance(finished.meters)) \(f.distanceUnit)", "Distance")
                        tile(MotionFormat.clock(finished.movingSec), "Moving time")
                    }
                    GridRow {
                        if finished.kind == .cycle {
                            tile("\(f.speed(kmh: RouteMath.speedKmh(seconds: finished.movingSec, meters: finished.meters))) \(f.speedUnit)", "Avg speed")
                        } else {
                            tile("\(f.pace(RouteMath.pace(seconds: finished.movingSec, meters: finished.meters, perMeters: f.perMeters))) /\(f.distanceUnit)", "Avg pace")
                        }
                        tile(finished.ascent >= 1 ? "\(Int(finished.ascent.rounded())) m" : "—", "Climb")
                    }
                }
                if toHealth {
                    Label("Also saved to Apple Health", systemImage: "heart.fill")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Button(action: close) { Text("Done").frame(maxWidth: .infinity).fontWeight(.semibold) }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .accessibilityIdentifier("activity.done")
            }
            .padding()
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("")
    }

    private func tile(_ value: String, _ label: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.weight(.bold)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.6)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.background.secondary, in: .rect(cornerRadius: 14))
    }
}

/// Today's row for an activity in progress, or one the app was closed during.
struct ActivityBanner: View {
    @Environment(ActivityTracker.self) private var tracker
    @Environment(GymStore.self) private var store
    let open: () -> Void

    var body: some View {
        let f = store.motionFormat
        if tracker.isActive {
            Button(action: open) {
                LinkRow(symbol: tracker.kind.symbol, tint: .accentColor,
                        title: Text(tracker.phase == .paused ? "\(tracker.kind.title) paused" : "\(tracker.kind.title) in progress"),
                        subtitle: "\(f.distance(tracker.meters)) \(f.distanceUnit)", trailing: "chevron.forward")
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("today.activityInProgress")
        } else if let d = tracker.recovered {
            VStack(alignment: .leading, spacing: 10) {
                LinkRow(symbol: d.kind.symbol, tint: .orange, title: Text("Unfinished \(d.kind.title.lowercased())"),
                        subtitle: "\(d.startedAt.formatted(date: .abbreviated, time: .shortened)) · \(f.distance(d.meters)) \(f.distanceUnit)",
                        trailing: "exclamationmark.circle")
                HStack {
                    Button("Save it") { tracker.saveRecovered() }.buttonStyle(.borderedProminent)
                    Button("Discard", role: .destructive) { tracker.discardRecovered() }.buttonStyle(.bordered)
                }
                .controlSize(.small)
            }
        }
    }
}
