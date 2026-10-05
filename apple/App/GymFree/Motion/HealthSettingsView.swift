import OpenGymCore
import SwiftUI

/// Settings → Apple Health: off until turned on here, which is the only place GymFree asks
/// for Health permission.
struct HealthSettingsView: View {
    @Environment(HealthSync.self) private var health
    @Environment(GymStore.self) private var store
    @Environment(\.openURL) private var openURL
    @AppStorage(HealthSync.Key.workouts) private var workouts = true
    @AppStorage(HealthSync.Key.weight) private var weight = true
    @State private var connecting = false
    @State private var latest: HealthSync.BodyMass?
    @State private var steps: Int?
    @State private var imported = false

    private var unit: String { store.prefs()?.unit ?? "kg" }

    var body: some View {
        List {
            if !health.isAvailable {
                ContentUnavailableView("Apple Health isn’t available on this device.", systemImage: "heart.slash")
                    .listRowBackground(Color.clear)
            } else {
                Section {
                    Toggle(isOn: Binding(get: { health.enabled }, set: { on in toggle(on) })) {
                        Label("Connect to Apple Health", systemImage: "heart.fill")
                    }
                    .disabled(connecting)
                    .accessibilityIdentifier("health.toggle")
                } footer: {
                    Text("GymFree can save your workouts, walks, runs, rides and weigh-ins to Apple Health, and read your body weight and steps. Health data stays on your iPhone and in Apple Health: GymFree has no server and never sends it anywhere.")
                }
                if let error = health.lastError {
                    Section { Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.orange) }
                }
                if health.enabled {
                    Section {
                        Toggle(isOn: $workouts) { Label("Workouts, walks, runs and rides", systemImage: "figure.walk") }
                        Toggle(isOn: $weight) { Label("Weigh-ins", systemImage: "scalemass") }
                    } header: {
                        Text("Save to Health")
                    } footer: {
                        if (workouts && !health.mayWriteWorkouts) || (weight && !health.mayWriteWeight) {
                            Text("Health doesn’t let GymFree save all of this. Change it in the Health app: tap your picture, then Apps → GymFree.")
                                .foregroundStyle(.orange)
                        } else {
                            Text("Strength workouts are saved with their start and end time; GymFree does not estimate calories. Walks, runs and rides are saved with their distance and route.")
                        }
                    }
                    Section {
                        if let latest {
                            LabeledContent("Latest body weight") {
                                Text("\(Fmt.num(display(latest.kg))) \(unit) · \(latest.date.formatted(date: .abbreviated, time: .omitted))")
                            }
                            if !latest.ours {
                                Button(imported ? "Added to your weigh-ins" : "Add to my weigh-ins", systemImage: "square.and.arrow.down") {
                                    importWeight(latest)
                                }
                                .disabled(imported)
                            }
                        } else {
                            LabeledContent("Latest body weight", value: "—")
                        }
                        LabeledContent("Steps, 7-day average", value: steps.map { $0.formatted() } ?? "—")
                    } header: {
                        Text("From Health")
                    } footer: {
                        Text("The step average can set the activity in Calories & food. A dash means Health has none, or GymFree may not read it (Health never says which).")
                    }
                    Section {
                        Button("Open the Health app", systemImage: "arrow.up.forward.app") {
                            if let url = URL(string: "x-apple-health://") { openURL(url) }
                        }
                    }
                }
            }
        }
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: health.enabled) { await loadReads() }
    }

    private func toggle(_ on: Bool) {
        if on {
            connecting = true
            Task {
                await health.connect()
                connecting = false
                await loadReads()
            }
        } else {
            // Health keeps what was saved, and the permissions stay in the Health app.
            health.enabled = false
        }
    }

    private func loadReads() async {
        guard health.enabled else { latest = nil; steps = nil; return }
        latest = await health.latestBodyMass()
        steps = await health.averageSteps()
    }

    private func display(_ kg: Double) -> Double { unit == "lb" ? kg / 0.45359237 : kg }

    /// Into the weigh-ins on the day it was measured; not written back to Health.
    private func importWeight(_ b: HealthSync.BodyMass) {
        let value = (display(b.kg) * 10).rounded() / 10
        if store.logWeight(value, on: Fmt.todayISO(b.date)) != nil { imported = true }
    }
}
