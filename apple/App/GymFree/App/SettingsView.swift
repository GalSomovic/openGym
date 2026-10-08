import OpenGymCore
import SwiftUI

struct SettingsView: View {
    @AppStorage(WorkoutSession.Pref.voice) private var voice = true
    @AppStorage(WorkoutSession.Pref.restAlarm) private var restAlarm = false
    @AppStorage(WorkoutSession.Pref.guidedDefault) private var guidedDefault = false
    @Environment(WorkoutSession.self) private var session
    @Environment(GymStore.self) private var store
    @Environment(HealthSync.self) private var health
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
                    NavigationLink { HealthSettingsView() } label: {
                        LabeledContent {
                            Text(health.enabled ? "On" : "Off")
                        } label: {
                            Label("Apple Health", systemImage: "heart")
                        }
                    }
                    .accessibilityIdentifier("settings.health")
                } footer: {
                    Text("Save workouts, walks and weigh-ins to Apple Health, and read your weight and steps. Off unless you turn it on.")
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
                        .accessibilityIdentifier("settings.about")
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

/// About: version, health and privacy, the licences and credits, and the AGPL notices
/// (section 5(d): copyright, no warranty, the licence and where the source is).
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
                NavigationLink { HealthSafetyView() } label: {
                    Label("Health & safety", systemImage: "heart.text.square")
                }
                .accessibilityIdentifier("about.healthSafety")
                NavigationLink { PrivacyPolicyView() } label: {
                    Label("Privacy policy", systemImage: "hand.raised")
                }
                Link(destination: LegalLinks.support) {
                    Label("Help and feedback", systemImage: "questionmark.bubble")
                }
            } footer: {
                Text("General fitness information, not medical advice. Eating-disorder support and helplines are under Health & safety.")
            }
            Section {
                NavigationLink { LicencesView() } label: {
                    Label("Licences & credits", systemImage: "c.circle")
                }
                .accessibilityIdentifier("about.licences")
                NavigationLink { OpenSourceLicencesView() } label: {
                    Label("Open-source licences", systemImage: "doc.plaintext")
                }
                .accessibilityIdentifier("about.openSource")
                NavigationLink { LegalNoticesView() } label: {
                    Label("Terms & disclaimers", systemImage: "doc.text")
                }
                .accessibilityIdentifier("about.legal")
                Link(destination: LegalLinks.sourceCode) {
                    Label("Source code", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                .accessibilityIdentifier("about.sourceCode")
            } header: {
                Text("Legal")
            } footer: {
                Text("openGym © 2026 Duarte Santos. GymFree changes © 2026 Gal Somovic. GymFree is a modified version of openGym and is free software under the GNU Affero General Public License v3.0 or later: you may share and change it under that licence, whose full text is under Open-source licences. It comes with ABSOLUTELY NO WARRANTY. The complete source code is at the Source code link.")
            }
            Section {
                Link(destination: LegalLinks.openGym) {
                    Label("openGym by Duarte Santos", systemImage: "heart")
                }
                Link(destination: LegalLinks.ascendAPI) {
                    Label("ExerciseDB by AscendAPI", systemImage: "figure.run")
                }
                Link(destination: LegalLinks.dvidsCopyright) {
                    Label("DVIDS, U.S. Department of War", systemImage: "video")
                }
                Link(destination: LegalLinks.muscleMap) {
                    Label("MuscleMap by Melih Colpan (MIT)", systemImage: "figure.stand")
                }
                NavigationLink { MediaCreditsView() } label: {
                    Label("Exercise media credits", systemImage: "photo.on.rectangle")
                }
                Link(destination: LegalLinks.usda) {
                    Label("USDA FoodData Central", systemImage: "fork.knife")
                }
            } header: {
                Text("Thanks to")
            } footer: {
                Text("GymFree is an independent native version of openGym and runs openGym’s own training engine. Exercise animations © AscendAPI (ExerciseDB), used under its free non-commercial terms. Most videos are U.S. military fitness clips from DVIDS (public domain); others come from wger, Wikimedia Commons, Feeel and Pixabay under their own licences (mostly CC BY-SA, modified). Food values: U.S. Department of Agriculture, Agricultural Research Service. FoodData Central, public domain (CC0). \(Disclaimers.dvids)")
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}


/// Title, author and licence of every free video and illustration (CC BY-SA requires it),
/// with links to the original and to the licence. Items under CC BY-SA say "modified":
/// fetch_free.py trims, resizes and re-encodes every file.
struct MediaCreditsView: View {
    /// Only this source ("DVIDS", "wger", …), or every source.
    var source: String? = nil

    private var groups: [(key: String, value: [MediaLibrary.Credit])] {
        let items = MediaLibrary.credits.filter { source == nil || $0.source == source }
        return Dictionary(grouping: items, by: \.source).sorted { $0.key < $1.key }
    }

    var body: some View {
        List {
            ForEach(groups, id: \.key) { name, items in
                Section {
                    ForEach(items) { c in
                        VStack(alignment: .leading, spacing: 3) {
                            Text(verbatim: "“\(c.title)”").font(.footnote.weight(.semibold))
                            Text(c.credit).font(.footnote)
                            HStack(spacing: 12) {
                                if let link = c.link {
                                    Link("Original", destination: link)
                                }
                                ForEach(c.licenseLinks, id: \.url) { l in
                                    Link(l.name, destination: l.url)
                                }
                            }
                            .font(.caption)
                            .buttonStyle(.borderless)
                        }
                        .accessibilityElement(children: .contain)
                    }
                } header: {
                    Text(verbatim: name)
                } footer: {
                    footer(name)
                }
            }
        }
        .navigationTitle(source.map { Text(verbatim: $0) } ?? Text("Media credits"))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func footer(_ source: String) -> some View {
        switch source {
        case "DVIDS":
            Text("Trimmed, resized, without sound. \(Disclaimers.dvids)")
        case "Pixabay":
            Text("Trimmed, cropped and resized. Credit isn't required by the Pixabay Content License but is given anyway.")
        default:
            Text("Modified for GymFree: trimmed, resized and re-encoded (pictures put on a dark background). Shared under the same licence as the original.")
        }
    }
}
