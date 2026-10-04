import OpenGymCore
import SwiftUI

/// openGym's Exercises screen: search, body part and equipment chips, favourites first.
struct LibraryView: View {
    @Environment(GymStore.self) private var store
    @Environment(ExerciseCatalog.self) private var catalog

    @State private var path: [String] = DebugLaunch.detail.map { [$0] } ?? []

    var body: some View {
        NavigationStack(path: $path) {
            ExerciseList { id in
                ExerciseDetailView(exerciseId: id)
            } trailing: { id in
                AddToPlanButton(exerciseId: id)
            }
            .navigationTitle("Exercises")
            .navigationDestination(for: String.self) { id in ExerciseDetailView(exerciseId: id) }
        }
    }
}

/// The filtered exercise list shared by the library and the pickers. `destination` opens an
/// exercise; `trailing` puts a button on each row.
struct ExerciseList<Destination: View, Trailing: View>: View {
    @Environment(GymStore.self) private var store
    @Environment(ExerciseCatalog.self) private var catalog
    @ViewBuilder var destination: (String) -> Destination
    @ViewBuilder var trailing: (String) -> Trailing
    var onSelect: ((String) -> Void)? = nil

    @State private var query = ""
    @State private var bodyPart = ""
    @State private var equipment = ""
    @State private var showAll = false
    @State private var result: LibraryResult?
    @State private var bests: [String: Double] = [:]

    private var filterKey: String { "\(query)|\(bodyPart)|\(equipment)|\(showAll)|\(store.revision)" }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    ChipRow(allLabel: "All", options: catalog.bodyParts, selection: $bodyPart)
                    if let result, result.equipment.count > 1 {
                        ChipRow(allLabel: "Any equipment", options: result.equipment, selection: $equipment)
                    }
                    if result?.profile != nil || showAll {
                        Toggle(isOn: $showAll) {
                            Text("Include equipment I don’t have").font(.footnote)
                        }
                        .padding(.horizontal)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
            }
            Section {
                ForEach(result?.ids ?? [], id: \.self) { id in
                    if let e = catalog[id] {
                        row(e)
                    }
                }
            } footer: {
                Text(ExerciseMedia.credit).font(.caption2)
            }
        }
        .listStyle(.plain)
        .searchable(text: $query, prompt: Text("Search exercises"))
        .overlay {
            if let result, result.ids.isEmpty {
                ContentUnavailableView.search(text: query)
            }
        }
        .task(id: filterKey) {
            let r = store.browse(query: query, bodyPart: bodyPart, equipment: equipment, showAll: showAll)
            result = r
            if let r, r.eq != equipment { equipment = r.eq }
            bests = store.bests(Array((r?.ids ?? []).prefix(400)))
        }
        .onChange(of: bodyPart) { equipment = "" }
    }

    @ViewBuilder
    private func row(_ e: ExerciseBrief) -> some View {
        let content = HStack(spacing: 12) {
            ExerciseThumb(exerciseId: e.id)
            VStack(alignment: .leading, spacing: 2) {
                Text(e.displayName).font(.body.weight(.medium)).lineLimit(2)
                Text(catalog.subtitle(e)).font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
            }
            Spacer(minLength: 4)
            if let best = bests[e.id] {
                Text(Fmt.num(best))
                    .font(.caption.weight(.semibold)).monospacedDigit()
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(.tint.opacity(0.18), in: .capsule)
                    .accessibilityLabel(Text("Best \(Fmt.num(best))"))
            }
            trailing(e.id)
        }
        if let onSelect {
            Button { onSelect(e.id) } label: { content.contentShape(Rectangle()) }
                .buttonStyle(.plain)
        } else {
            NavigationLink { destination(e.id) } label: { content }
        }
    }
}

/// "Plan" on a library row: pick a routine, then the exercise's settings.
struct AddToPlanButton: View {
    let exerciseId: String
    @State private var presented = false

    var body: some View {
        Button { presented = true } label: { Image(systemName: "plus") }
            .buttonStyle(.bordered)
            .buttonBorderShape(.circle)
            .controlSize(.small)
            .accessibilityLabel(Text("Add to a routine"))
            .sheet(isPresented: $presented) { AddToRoutineSheet(exerciseId: exerciseId) }
    }
}
