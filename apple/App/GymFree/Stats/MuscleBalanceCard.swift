import OpenGymCore
import SwiftUI

/// Stats.jsx MuscleBalance: where the training went (sets per muscle, or only the hard ones),
/// how fatigued each muscle is, and how much strength each has kept. A tapped muscle shows its
/// number, or on the strength map its exercises with their estimated 1RM.
struct MuscleBalanceCard: View {
    @Environment(GymStore.self) private var store
    @AppStorage("gf.muscleView") private var view = "balance"
    @AppStorage("gf.muscleWindow") private var window = 7
    @State private var hard = false
    @State private var selected: String?

    var body: some View {
        if let m = store.muscleMap(view: view, window: window, hard: hard, selected: selected, today: Day.today) {
            VStack(alignment: .leading, spacing: 12) {
                Picker("Map", selection: Binding(get: { m.view }, set: { view = $0; selected = nil })) {
                    ForEach(m.views, id: \.label) { o in Text(o.label).tag(o.value.string ?? "balance") }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("muscles.view")
                header(m)
                if m.view == "balance", let windows = m.windows {
                    Picker("Period", selection: Binding(get: { m.win ?? 7 }, set: { window = $0; selected = nil })) {
                        ForEach(windows, id: \.label) { o in Text(o.label).tag(Int(o.value.number ?? 7)) }
                    }
                    .pickerStyle(.segmented)
                }
                if let empty = m.empty {
                    Text(empty).font(.subheadline).foregroundStyle(.secondary)
                } else {
                    BodyMapView(levels: m.levels, palette: BodyPalette(m.palette), selected: m.selected, figure: m.body) { slug in
                        withAnimation(.snappy) { selected = selected == slug ? nil : slug }
                    }
                    .frame(maxHeight: 300)
                    BodyMapLegend(items: m.legend, palette: BodyPalette(m.palette))
                    if let note = m.note { Text(note).font(.footnote).foregroundStyle(.secondary) }
                    details(m)
                }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private func header(_ m: MuscleMapData) -> some View {
        HStack {
            Text(m.title).font(.headline).lineLimit(1).layoutPriority(1)
            if let sub = m.subtitle { Text("· \(sub)").font(.subheadline).foregroundStyle(.secondary).lineLimit(1) }
            Spacer()
            if m.hardShown == true, let label = m.hardLabel {
                Button { hard.toggle(); selected = nil } label: { Label(label, systemImage: "flame") }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(m.hard == true ? .yellow : .secondary)
            }
        }
    }

    @ViewBuilder
    private func details(_ m: MuscleMapData) -> some View {
        if let name = m.selectedName, let value = m.selectedValue {
            HStack {
                Text(name).fontWeight(.semibold)
                Spacer()
                Text(value).foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("muscles.selected")
        }
        if m.view == "balance" {
            if m.selected == nil { ForEach(m.top ?? []) { bar($0, color: m.hard == true ? .yellow : .accentColor) } }
            if let title = m.missedTitle, let missed = m.missed {
                Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary).textCase(.uppercase)
                FlowTags(tags: missed)
            }
            if let all = m.allWorked { Text(all).font(.footnote).foregroundStyle(.secondary) }
        }
        if m.view == "strength" {
            if let title = m.exercisesTitle {
                Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary).textCase(.uppercase)
                if let rows = m.exercises, !rows.isEmpty {
                    ForEach(rows) { row in
                        NavigationLink(value: TodayRouter.Route.progress(row.id)) { strengthRow(row) }
                            .buttonStyle(.plain)
                    }
                } else if let none = m.noExercises {
                    Text(none).font(.footnote).foregroundStyle(.secondary)
                }
            }
            if let hint = m.hint { Text(hint).font(.footnote).foregroundStyle(.secondary) }
            ForEach(m.detrained ?? []) { bar($0, color: .accentColor) }
        }
    }

    private func strengthRow(_ row: StrengthExercise) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(row.name).lineLimit(1)
                    Text(row.role).font(.caption2).foregroundStyle(.secondary)
                }
                Text(row.estimate).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                Text(row.value).font(.caption).monospacedDigit()
                Meter(frac: row.frac, color: .accentColor).frame(width: 70)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("muscles.exercise")
    }

    private func bar(_ b: MuscleBar, color: Color) -> some View {
        HStack(spacing: 10) {
            Text(b.name).font(.subheadline).frame(width: 96, alignment: .leading).lineLimit(1)
            Meter(frac: b.frac, color: color)
            VStack(alignment: .trailing, spacing: 1) {
                Text(b.value).font(.caption).monospacedDigit()
                if let d = b.detail { Text(d).font(.caption2).foregroundStyle(.secondary) }
            }
            .frame(minWidth: 70, alignment: .trailing)
        }
        .accessibilityElement(children: .combine)
    }
}

/// A thin filled bar, 0–1.
struct Meter: View {
    let frac: Double
    var color: Color = .accentColor

    var body: some View {
        GeometryReader { geo in
            Capsule().fill(.quaternary)
                .overlay(alignment: .leading) {
                    Capsule().fill(color).frame(width: max(frac > 0 ? 4 : 0, geo.size.width * min(1, frac)))
                }
        }
        .frame(height: 6)
    }
}
