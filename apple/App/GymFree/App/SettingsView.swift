import OpenGymCore
import SwiftUI

struct SettingsView: View {
    @AppStorage(WorkoutSession.Pref.voice) private var voice = true
    @AppStorage(WorkoutSession.Pref.restAlarm) private var restAlarm = false
    @AppStorage(WorkoutSession.Pref.guidedDefault) private var guidedDefault = false
    @Environment(WorkoutSession.self) private var session
    @Environment(GymStore.self) private var store
    @State private var unitAsk: String?

    private var equipmentSummary: String {
        _ = store.revision
        guard let e = store.equipment(), e.filterOn else { return String(localized: "All") }
        return e.selected.isEmpty ? String(localized: "Bodyweight only") : String(localized: "\(e.selected.count) selected")
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink { EquipmentSettingsView() } label: {
                        LabeledContent {
                            Text(equipmentSummary)
                        } label: {
                            Label("Equipment", systemImage: "dumbbell")
                        }
                    }
                }
                if let p = store.prefs() {
                    general(p)
                    duringAWorkout(p)
                }
                Section {
                    Toggle(isOn: $guidedDefault) { Label("Start workouts in guided mode", systemImage: "figure.strengthtraining.traditional") }
                    Toggle(isOn: $voice) { Label("Spoken cues", systemImage: "speaker.wave.2") }
                    Toggle(isOn: $restAlarm) { Label("Rest alarm", systemImage: "alarm") }
                } header: {
                    Text("Guided workouts")
                } footer: {
                    Text("Cues play over your music: it ducks while GymFree speaks, then comes back up. The rest alarm rings through silent mode and Focus when a rest ends while your phone is locked.")
                }
                ReminderSettingsSection()
                Section("Appearance") {
                    Picker(selection: Binding(get: { store.pick("gfTheme", as: String.self) ?? "system" },
                                              set: { store.patch(["gfTheme": $0]) })) {
                        Text("System").tag("system")
                        Text("Dark").tag("dark")
                        Text("Light").tag("light")
                    } label: { Label("Theme", systemImage: "circle.lefthalf.filled") }
                    Picker(selection: Binding(get: { store.pick("body", as: String.self) == "female" ? "female" : "male" },
                                              set: { store.patch(["body": $0]) })) {
                        Text("Male").tag("male")
                        Text("Female").tag("female")
                    } label: { Label("Body diagram", systemImage: "figure.stand") }
                    Toggle(isOn: Binding(get: { store.pick("timerFlash", as: Bool.self) == true },
                                         set: { store.patch(["timerFlash": $0]) })) {
                        Label("Flash the screen when a rest ends", systemImage: "light.max")
                    }
                }
                Section {
                    NutritionSettingsRow()
                } footer: {
                    Text("A daily calorie and protein target and a simple food log, based on independent research. Off unless you turn it on.")
                }
                Section {
                    NavigationLink { DataSettingsView() } label: {
                        Label("Data", systemImage: "externaldrive")
                    }
                } footer: {
                    Text("Back up, restore, import from FitNotes, Strong, Hevy or Apple Health, or start over.")
                }
                Section {
                    NavigationLink { AboutView() } label: { Label("About GymFree", systemImage: "info.circle") }
                }
            }
            .onChange(of: voice) { session.syncSettings() }
            .confirmationDialog(Text("Convert to \(unitAsk ?? "")?"), isPresented: Binding(get: { unitAsk != nil }, set: { if !$0 { unitAsk = nil } }),
                                titleVisibility: .visible, presenting: unitAsk) { unit in
                Button("Convert the numbers") { store.setUnit(unit, convert: true) }
                Button("Keep the numbers, change the label") { store.setUnit(unit, convert: false) }
                Button("Cancel", role: .cancel) {}
            } message: { _ in
                Text("Every stored weight — logged sets, working weights, routine targets, body weight, bar weights — is in \(store.prefs()?.unit ?? "kg"). Convert the numbers, or keep them and only change the label?")
            }
            .navigationTitle("Settings")
        }
    }

    /* ------------------------------ openGym's settings ------------------------------ */

    /// A profile setting, written through the engine like every other change.
    private func pref<T>(_ value: T, _ key: String, then: @escaping () -> Void = {}) -> Binding<T> {
        Binding(get: { value }, set: { store.patch([key: $0]); then() })
    }

    @ViewBuilder
    private func general(_ p: Prefs) -> some View {
        Section {
            Picker(selection: Binding(get: { p.unit }, set: { if $0 != p.unit { unitAsk = $0 } })) {
                Text("kg").tag("kg")
                Text("lb").tag("lb")
            } label: { Label("Weight unit", systemImage: "scalemass") }
            // Speeds stay stored in km/h; only what is shown and typed follows this (lib/speed.js).
            Picker(selection: pref(p.speedUnit, "speedUnit")) {
                Text("km/h").tag("kmh")
                Text("mph").tag("mph")
            } label: { Label("Speed unit", systemImage: "figure.run") }
            Picker(selection: pref(p.wdec, "wdec") { Fmt.sync(store) }) {
                Text("0.5").tag(1)
                Text("0.25").tag(2)
            } label: { Label("Weight decimals", systemImage: "number") }
            Picker(selection: pref(p.weekStart, "weekStart")) {
                Text(Fmt.weekday(1)).tag(1)
                Text(Fmt.weekday(0)).tag(0)
            } label: { Label("Week starts on", systemImage: "calendar") }
        } header: {
            Text("General")
        } footer: {
            Text("Switching the unit offers to convert every stored weight. Weight decimals only change how precisely weights are shown.")
        }
    }

    @ViewBuilder
    private func duringAWorkout(_ p: Prefs) -> some View {
        Section {
            Toggle(isOn: pref(p.weighIn, "weighIn")) {
                Label("Weigh in before workouts", systemImage: "scalemass.fill")
            }
            Picker(selection: pref(p.startFrom, "startFrom")) {
                Text("Your plan").tag("plan")
                Text("Your last session").tag("last")
            } label: { Label("Planned sessions start from", systemImage: "list.clipboard") }
            Picker(selection: pref(p.restSec, "restSec")) {
                Text("Off").tag(0.0)
                ForEach(options([60, 90, 120, 150, 180], p.restSec), id: \.self) { Text("\(Int($0))s").tag($0) }
            } label: { Label("Rest timer", systemImage: "timer") }
            Picker(selection: pref(p.restPauseSec, "restPauseSec")) {
                ForEach(options([10, 15, 20, 30], p.restPauseSec), id: \.self) { Text("\(Int($0))s").tag($0) }
            } label: { Label("Rest-pause rest", systemImage: "bolt") }
            Picker(selection: Binding(get: { p.effort }, set: { store.setEffort($0) })) {
                Text("Off").tag("none")
                Text("RIR").tag("rir")
                Text("RPE").tag("rpe")
            } label: { Label("Effort per set", systemImage: "target") }
            Toggle(isOn: pref(p.timedSetOvertime, "timedSetOvertime")) {
                Label("Keep timing after target", systemImage: "stopwatch")
            }
            Toggle(isOn: pref(p.keepAwake, "keepAwake")) {
                Label("Keep screen awake", systemImage: "sun.max")
            }
            Toggle(isOn: pref(p.sound, "sound") { session.syncSettings() }) {
                Label("Sounds", systemImage: "bell")
            }
            Toggle(isOn: pref(p.vibrate, "vibrate") { session.syncSettings() }) {
                Label("Vibrate", systemImage: "iphone.radiowaves.left.and.right")
            }
        } header: {
            Text("During a workout")
        } footer: {
            Text("Effort per set asks how hard each set was: reps in reserve (RIR) or rate of perceived exertion (RPE). Timed sets that keep timing continue up to 15 extra minutes; tap Done to log the actual duration.")
        }
    }

    /// The choices, plus the current value when it is not one of them (set elsewhere).
    private func options(_ values: [Double], _ current: Double) -> [Double] {
        values.contains(current) || current == 0 ? values : (values + [current]).sorted()
    }
}

/// Credits and licences: openGym (AGPL v3), the ExerciseDB animations, MuscleMap.
struct AboutView: View {
    private var version: String {
        let info = Bundle.main.infoDictionary
        return "\(info?["CFBundleShortVersionString"] as? String ?? "") (\(info?["CFBundleVersion"] as? String ?? ""))"
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("GymFree").font(.title2.weight(.bold))
                    Text("Free forever. No ads, no account, no subscription. Your data stays on your device.")
                        .foregroundStyle(.secondary)
                    Text("Version \(version)").font(.footnote).foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
            Section {
                Link(destination: URL(string: "https://github.com/DuarteSantos8/openGym")!) {
                    Label("openGym by Duarte Santos", systemImage: "heart")
                }
                Link(destination: URL(string: "https://github.com/GalSomovic/openGym/tree/native-apple")!) {
                    Label("GymFree source code", systemImage: "chevron.left.forwardslash.chevron.right")
                }
            } header: {
                Text("Built on openGym")
            } footer: {
                Text("GymFree is an independent native version of openGym and runs openGym’s own training engine. Both are free software under the GNU Affero General Public License v3.0; the full source is available at the link above.")
            }
            Section {
                Link(destination: URL(string: "https://oss.exercisedb.dev")!) {
                    Label("ExerciseDB by AscendAPI", systemImage: "figure.run")
                }
                Link(destination: URL(string: "https://github.com/melihcolpan/MuscleMap")!) {
                    Label("MuscleMap by Melih Colpan (MIT)", systemImage: "figure.stand")
                }
                NavigationLink { MediaCreditsView() } label: {
                    Label("Exercise media credits", systemImage: "photo.on.rectangle")
                }
            } header: {
                Text("Thanks to")
            } footer: {
                Text("Exercise animations © AscendAPI (ExerciseDB), used under its free non-commercial licence. Videos and illustrations from wger, Wikimedia Commons and Feeel are used under their open licences (mostly CC BY-SA 4.0; US Army clips are public domain).")
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}


/// Author and licence of every free video and illustration in the app (CC BY-SA requires it).
struct MediaCreditsView: View {
    var body: some View {
        List {
            ForEach(Dictionary(grouping: MediaLibrary.credits, by: \.source).sorted { $0.key < $1.key }, id: \.key) { source, items in
                Section(source) {
                    ForEach(items) { c in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.credit).font(.footnote)
                            if let link = c.link {
                                Link(link.absoluteString, destination: link).font(.caption2).lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Media credits")
        .navigationBarTitleDisplayMode(.inline)
    }
}
