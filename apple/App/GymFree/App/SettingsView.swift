import OpenGymCore
import SwiftUI

struct SettingsView: View {
    @AppStorage(WorkoutSession.Pref.voice) private var voice = true
    @AppStorage(WorkoutSession.Pref.restAlarm) private var restAlarm = false
    @AppStorage(WorkoutSession.Pref.guidedDefault) private var guidedDefault = false
    @Environment(WorkoutSession.self) private var session
    @Environment(GymStore.self) private var store

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
                Section {
                    Toggle(isOn: $guidedDefault) { Label("Start workouts in guided mode", systemImage: "figure.strengthtraining.traditional") }
                    Toggle(isOn: $voice) { Label("Spoken cues", systemImage: "speaker.wave.2") }
                    Toggle(isOn: $restAlarm) { Label("Rest alarm", systemImage: "alarm") }
                } header: {
                    Text("Guided workouts")
                } footer: {
                    Text("Cues play over your music: it ducks while GymFree speaks, then comes back up. The rest alarm rings through silent mode and Focus when a rest ends while your phone is locked.")
                }
                Section {
                    NavigationLink { AboutView() } label: { Label("About GymFree", systemImage: "info.circle") }
                }
            }
            .onChange(of: voice) { session.syncSettings() }
            .navigationTitle("Settings")
        }
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
