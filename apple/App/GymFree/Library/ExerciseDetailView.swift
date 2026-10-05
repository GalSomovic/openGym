import OpenGymCore
import SwiftUI

struct ExerciseDetailView: View {
    let exerciseId: String
    @Environment(GymStore.self) private var store
    @Environment(ExerciseCatalog.self) private var catalog
    @State private var detail: ExerciseDetail?
    @State private var note = ""
    @State private var addPresented = false
    @State private var editingCustom = false
    @Environment(\.dismiss) private var dismissDetail

    var body: some View {
        List {
            Section {
                ExerciseAnimation(exerciseId: exerciseId, toggle: true)
                    .frame(maxWidth: 420)
                    .frame(maxWidth: .infinity)
                    .clipShape(.rect(cornerRadius: 18))
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            } footer: {
                if MediaLibrary.options(for: exerciseId).count > 1 {
                    Text("Use the arrows to switch between the versions available for this exercise.")
                        .font(.caption2).frame(maxWidth: .infinity)
                }
            }
            if let detail {
                Section {
                    FlowTags(tags: tags(detail))
                    if detail.best > 0 {
                        LabeledContent("Best", value: "\(Fmt.num(detail.best)) \(store.pick("unit", as: String.self) ?? "kg")")
                    }
                }
                if !detail.st.isEmpty {
                    Section("Instructions") {
                        ForEach(Array(detail.st.enumerated()), id: \.offset) { i, step in
                            HStack(alignment: .firstTextBaseline, spacing: 10) {
                                Text("\(i + 1)").font(.subheadline.weight(.bold)).foregroundStyle(.tint)
                                    .frame(width: 20, alignment: .trailing)
                                Text(step)
                            }
                        }
                    }
                }
                Section {
                    TextField("Seat 4, pin 7…", text: $note, axis: .vertical)
                        .onSubmit { store.setStandingNote(exerciseId, note) }
                } header: {
                    Text("Your note")
                } footer: {
                    Text("Shown every time you do this exercise.")
                }
                Section {
                    Button("Add to a routine", systemImage: "plus.circle.fill") { addPresented = true }
                    // sheets.jsx ExerciseDetail's History: the curves and the sessions behind them.
                    if hasHistory {
                        NavigationLink { ExerciseProgressView(exerciseId: exerciseId) } label: {
                            Label("Progress", systemImage: "chart.xyaxis.line")
                        }
                        .accessibilityIdentifier("detail.progress")
                    }
                }
                // No one-rep max for cardio or an assistance machine (the engine says which).
                OneRMSections(exerciseId: exerciseId)
            }
        }
        .navigationTitle(detail?.displayName ?? catalog.name(exerciseId))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if exerciseId.hasPrefix("c"), store.query("custom", "get", [exerciseId], as: JSONValue?.self) != nil {
                ToolbarItem(placement: .primaryAction) {
                    Button("Edit") { editingCustom = true }
                }
            }
            if let detail {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        store.toggleFavourite(exerciseId)
                        self.detail = store.exerciseDetail(exerciseId)
                    } label: {
                        Image(systemName: detail.fav ? "star.fill" : "star")
                    }
                    .accessibilityLabel(Text(detail.fav ? "Remove from favourites" : "Add to favourites"))
                }
            }
        }
        .sheet(isPresented: $addPresented) { AddToRoutineSheet(exerciseId: exerciseId) }
        .sheet(isPresented: $editingCustom, onDismiss: {
            // Deleted: leave the page; edited: show the new details.
            if catalog[exerciseId] == nil { dismissDetail() } else { detail = store.exerciseDetail(exerciseId) }
        }) { CustomExerciseForm(editing: exerciseId) }
        .onAppear {
            detail = store.exerciseDetail(exerciseId)
            note = detail?.note ?? ""
        }
        .onDisappear { if note != (detail?.note ?? "") { store.setStandingNote(exerciseId, note) } }
    }

    private var hasHistory: Bool { (store.exerciseProgress(exerciseId)?.sessions ?? 0) > 0 }

    private func tags(_ d: ExerciseDetail) -> [String] {
        var out: [String] = []
        if d.cardio { out.append(String(localized: "Cardio")) }
        out.append(catalog.muscleName(d.tg ?? d.bp))
        if let eq = d.eq { out.append(eq.capitalizedWords) }
        out += d.sm.prefix(3).map { catalog.muscleName($0) }
        return out
    }
}

/// Tags that wrap onto as many lines as they need.
struct FlowTags: View {
    let tags: [String]

    var body: some View {
        FlowLayout(spacing: 6) {
            ForEach(Array(tags.enumerated()), id: \.offset) { i, tag in
                Text(tag)
                    .font(.subheadline)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(i == 0 ? AnyShapeStyle(.tint.opacity(0.2)) : AnyShapeStyle(.quaternary.opacity(0.6)), in: .capsule)
            }
        }
        // A List row can measure this at another width than it lays it out at; taking the full
        // width keeps the measured height right when the chips wrap onto a second line.
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row { var indices: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows = [Row()]
        for (i, view) in subviews.enumerated() {
            let size = view.sizeThatFits(.unspecified)
            if !rows[rows.count - 1].indices.isEmpty, rows[rows.count - 1].width + spacing + size.width > width {
                rows.append(Row())
            }
            var row = rows[rows.count - 1]
            row.width += (row.indices.isEmpty ? 0 : spacing) + size.width
            row.height = max(row.height, size.height)
            row.indices.append(i)
            rows[rows.count - 1] = row
        }
        return rows
    }
}
