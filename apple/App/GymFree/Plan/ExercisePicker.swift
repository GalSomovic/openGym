import OpenGymCore
import SwiftUI

/// Choose an exercise: "+" adds it at once with its defaults; tapping the row opens its
/// settings (`configure`) first, the way openGym's picker works.
struct ExercisePickerSheet<Configure: View>: View {
    let title: LocalizedStringKey
    let onQuick: (_ exerciseId: String) -> Void
    @ViewBuilder let configure: (_ exerciseId: String) -> Configure
    @Environment(\.dismiss) private var dismiss
    @Environment(ExerciseCatalog.self) private var catalog
    @State private var path: [String] = []

    var body: some View {
        NavigationStack(path: $path) {
            ExerciseList(destination: { _ in EmptyView() }, trailing: { id in
                Button { onQuick(id) } label: { Image(systemName: "plus") }
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .controlSize(.small)
                    .accessibilityLabel(Text("Add now"))
            }, onSelect: { id in path.append(id) })
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
            .navigationDestination(for: String.self) { id in
                configure(id)
                    .navigationTitle(catalog.name(id))
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

/// Library "+": pick a routine (or a new one), then the exercise's settings.
struct AddToRoutineSheet: View {
    let exerciseId: String
    @Environment(GymStore.self) private var store
    @Environment(ExerciseCatalog.self) private var catalog
    @Environment(\.dismiss) private var dismiss
    @State private var path: [Target] = []

    private struct Target: Hashable { let routineId: String? }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    ForEach(store.routines) { r in
                        Button { path.append(Target(routineId: r.id)) } label: {
                            HStack(spacing: 12) {
                                RoutineIcon(emoji: r.emoji)
                                VStack(alignment: .leading) {
                                    Text(r.name).foregroundStyle(.primary)
                                    Text(Fmt.exercises(r.ex.count)).font(.subheadline).foregroundStyle(.secondary)
                                }
                                Spacer()
                                if r.ex.contains(where: { $0.id == exerciseId }) {
                                    Text("already in").font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    Button { path.append(Target(routineId: nil)) } label: {
                        Label("New routine", systemImage: "sparkles")
                    }
                } footer: {
                    Text("Pick a routine. Sets, reps and weight come next.")
                }
            }
            .navigationTitle("Add “\(catalog.name(exerciseId))”")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .navigationDestination(for: Target.self) { target in
                ExerciseConfigForm(exerciseId: exerciseId, routineId: target.routineId,
                                   start: store.configStart(exerciseId, existing: nil, routine: target.routineId),
                                   saveLabel: "Add to routine") { cfg in
                    store.addToRoutine(exerciseId, routine: target.routineId, config: cfg,
                                       newName: String(localized: "New routine"))
                    dismiss()
                }
                .navigationTitle(catalog.name(exerciseId))
            }
        }
    }
}
