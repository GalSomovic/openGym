import OpenGymCore
import SwiftUI

/// What you train with. Everything is on by default; "Bodyweight only" is for calisthenics.
/// Exercises that need something you don't have are hidden from the library and the pickers,
/// and flagged in your routines.
struct EquipmentSettingsView: View {
    @Environment(GymStore.self) private var store
    @State private var state: EquipmentState?

    var body: some View {
        List {
            if let state {
                Section {
                    Button("Select all", systemImage: "checkmark.circle") { set(state.all) }
                        .disabled(state.selected.count == state.all.count)
                    Button("Bodyweight only", systemImage: "figure.strengthtraining.functional") { set([]) }
                        .disabled(state.selected.isEmpty)
                } footer: {
                    Text(state.filterOn
                         ? "Showing \(state.selected.count) of \(state.all.count) kinds of equipment, plus bodyweight exercises."
                         : "All equipment is shown.")
                }
                Section {
                    Label {
                        HStack {
                            Text("Body weight")
                            Spacer()
                            Text("Always").foregroundStyle(.secondary)
                        }
                    } icon: { Image(systemName: "checkmark.circle.fill").foregroundStyle(.secondary) }
                    ForEach(state.all, id: \.self) { eq in
                        let on = state.selected.contains(eq)
                        Button {
                            set(on ? state.selected.filter { $0 != eq } : state.selected + [eq])
                        } label: {
                            Label {
                                Text(eq.capitalizedWords).foregroundStyle(.primary)
                            } icon: {
                                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(on ? Color.accentColor : .secondary)
                            }
                        }
                        .accessibilityAddTraits(on ? .isSelected : [])
                    }
                } header: {
                    Text("Equipment you have")
                }
            }
        }
        .navigationTitle("Equipment")
        .onAppear { state = store.equipment() }
    }

    private func set(_ selected: [String]) {
        state = store.setEquipment(selected, name: String(localized: "My equipment"))
    }
}
