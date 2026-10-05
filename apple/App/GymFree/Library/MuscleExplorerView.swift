import OpenGymCore
import SwiftUI

/// components/MuscleExplorer.jsx: the catalogue by muscle. Tap a muscle on the body (or its
/// chip, with how many exercises train it) to list them, primary targets marked, searchable.
struct MuscleExplorerView: View {
    @Environment(GymStore.self) private var store
    @Environment(ExerciseCatalog.self) private var catalog
    @State private var selected: String?
    @State private var query = ""
    @State private var showAll = false

    var body: some View {
        let data = store.exercisesByMuscle(selected, query: query, showAll: showAll)
        List {
            Section {
                BodyMapView(levels: selected.map { [$0: 4] } ?? [:], selected: selected) { pick($0) }
                    .frame(maxHeight: 320)
                    .padding(.vertical, 6)
                FlowLayout(spacing: 6) {
                    ForEach(data?.muscles ?? []) { m in
                        Button { pick(m.slug) } label: {
                            HStack(spacing: 4) {
                                Text(m.name)
                                Text("\(m.count)").foregroundStyle(.secondary)
                            }
                            .font(.subheadline)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(selected == m.slug ? AnyShapeStyle(.tint.opacity(0.25)) : AnyShapeStyle(.quaternary.opacity(0.6)), in: .capsule)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selected == m.slug ? .isSelected : [])
                        .accessibilityIdentifier("chip.\(m.slug)")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if data?.profile != nil || showAll {
                    Toggle("Include equipment I don’t have", isOn: $showAll).font(.footnote)
                }
            }
            if let data, data.selected != nil {
                Section {
                    ForEach(data.exercises) { e in
                        NavigationLink(value: e.id) {
                            HStack(spacing: 12) {
                                ExerciseThumb(exerciseId: e.id)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(catalog.name(e.id)).font(.body.weight(.medium)).lineLimit(2)
                                    Text(e.line).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                                }
                                Spacer(minLength: 4)
                                AddToPlanButton(exerciseId: e.id)
                            }
                        }
                    }
                    if data.exercises.isEmpty {
                        ContentUnavailableView.search(text: query)
                    }
                } header: {
                    HStack {
                        Text(data.title ?? "")
                        Spacer()
                        Button("Clear selection") { pick(data.selected ?? "") }.textCase(nil)
                    }
                }
            } else if let prompt = data?.prompt {
                Section {
                    Label(prompt, systemImage: "hand.tap").foregroundStyle(.secondary)
                }
            }
        }
        .searchable(text: $query, prompt: Text("Search exercises"))
    }

    private func pick(_ slug: String) {
        withAnimation(.snappy) { selected = selected == slug ? nil : slug }
    }
}
