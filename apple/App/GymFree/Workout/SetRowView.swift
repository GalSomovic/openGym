import OpenGymCore
import SwiftUI

/// One set row (Workout.jsx setrow): the set number with its menu, a cell per column, the
/// play button of a timed set, and the tick. A per-side set is an L and an R row.
struct SetRowView: View {
    let entry: Int
    let index: Int
    let row: SetRow
    let info: EntryRowInfo
    let view: EntryView
    @Environment(GymStore.self) private var store
    @Environment(WorkoutSession.self) private var session

    var body: some View {
        VStack(spacing: 4) {
            if info.side {
                HStack(alignment: .center, spacing: 8) {
                    numberMenu
                    VStack(spacing: 6) {
                        sideRow("L")
                        extras(side: "L")
                        sideRow("R")
                        extras(side: "R")
                    }
                }
            } else {
                HStack(spacing: 8) {
                    numberMenu
                    ForEach(Array(view.cols.enumerated()), id: \.offset) { _, col in
                        if let col { cell(col, value: value(col.f), side: nil) }
                    }
                    if view.timed && store.active?.editingWorkoutId == nil {
                        Button {
                            session.startHold(entry, index, plan: row.sec ?? 45)
                        } label: {
                            Image(systemName: "play.fill").frame(width: 34, height: 34)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.circle)
                        .disabled(row.isDone || session.hold != nil)
                        .accessibilityLabel(Text("Start set"))
                    }
                    check(done: row.isDone) { session.toggle(entry, index) }
                }
                extras(side: nil)
            }
            if let line = view.plateLines[String(index)] { PlateLineView(line: line) }
        }
        .padding(.vertical, 3)
        .opacity(row.isDone ? 0.75 : 1)
    }

    private var numberMenu: some View {
        Menu {
            if info.canDrop {
                Button("Drop set", systemImage: "arrow.down") { store.addDrop(entry, index) }
            }
            if info.canBurst {
                Button("Rest-pause burst", systemImage: "bolt") { store.addBurst(entry, index) }
            }
            Button("Remove this set", systemImage: "trash", role: .destructive) { store.removeSet(entry, at: index) }
                .disabled(store.active?.editingWorkoutId == nil && (store.active?.entries[safe: entry]?.sets.count ?? 0) <= 1)
        } label: {
            Text(info.warm ? "W" : "\(info.num)")
                .font(.subheadline.weight(.bold)).monospacedDigit()
                .foregroundStyle(info.warm ? Color.orange : .secondary)
                .frame(width: 26, height: 34)
        }
        .accessibilityLabel(Text(info.warm ? "Warm-up set \(info.num)" : "Set \(info.num)"))
    }

    private func sideRow(_ side: String) -> some View {
        let sd = row.sides?[side]
        return HStack(spacing: 8) {
            Text(side == "L" ? "L" : "R")
                .font(.caption.weight(.bold)).foregroundStyle(.secondary).frame(width: 14)
            ForEach(Array(view.cols.enumerated()), id: \.offset) { _, col in
                if let col {
                    let v: Double? = switch col.f {
                    case "w": sd?.w
                    case "r": sd?.r
                    case "rir": sd?.rir
                    case "rpe": sd?.rpe
                    default: nil
                    }
                    cell(col, value: v, side: side)
                }
            }
            check(done: sd?.done == true) { session.toggle(entry, index, side: side) }
        }
    }

    private func value(_ f: String) -> Double? {
        switch f {
        case "w": row.w
        case "r": row.r
        case "sec": row.sec
        case "min": row.min
        case "speed": info.speedShown ?? row.speed
        case "rir": row.rir
        case "rpe": row.rpe
        default: nil
        }
    }

    @ViewBuilder
    private func cell(_ col: EntryColumn, value: Double?, side: String?) -> some View {
        if let kind = col.eff {
            EffortCell(kind: kind, value: value, heading: col.hd) { v in
                session.rate(entry, index, field: col.f, value: v, side: side)
            } step: { dir in
                store.bump(entry, index, col.f, dir, side: side)
            }
        } else {
            SetValueCell(value: value, decimals: col.dec == true ? 2 : 0, label: col.hd) { v in
                if let side { store.setSideValue(entry, index, side, col.f, v) } else { store.setTyped(entry, index, col.f, v) }
            } step: { dir in
                store.bump(entry, index, col.f, dir, side: side)
            }
        }
    }

    private func check(done: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 30))
                .foregroundStyle(done ? Color.accentColor : Color.secondary)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.success, trigger: done) { old, new in !old && new && session.haptics }
        .accessibilityLabel(Text(done ? "Done" : "Mark set done"))
    }

    /// A set's drops and bursts, each editable (Workout.jsx subrow).
    @ViewBuilder
    private func extras(side: String?) -> some View {
        let source: (drops: [Drop], bursts: [Burst]) = if let side {
            (row.sides?[side]?.type == "dropset" ? row.sides?[side]?.drops ?? [] : [],
             row.sides?[side]?.type == "restpause" ? row.sides?[side]?.clusters ?? [] : [])
        } else {
            (row.isDropSet ? row.drops ?? [] : [], row.isRestPause ? row.clusters ?? [] : [])
        }
        ForEach(Array(source.drops.enumerated()), id: \.offset) { di, d in
            HStack(spacing: 8) {
                Text("Drop \(di + 1)").font(.caption).foregroundStyle(.secondary).frame(width: 56, alignment: .leading)
                SetValueCell(value: d.w, decimals: 2, label: "Weight", compact: true) { v in
                    if let v { store.setDrop(entry, index, di, "w", v, side: side) }
                } step: { store.bumpDrop(entry, index, di, "w", $0, side: side) }
                SetValueCell(value: d.r, decimals: 0, label: "Reps", compact: true) { v in
                    if let v { store.setDrop(entry, index, di, "r", v, side: side) }
                } step: { store.bumpDrop(entry, index, di, "r", $0, side: side) }
                Button { store.removeDrop(entry, index, di) } label: { Image(systemName: "xmark") }
                    .buttonStyle(.borderless).accessibilityLabel(Text("Remove drop"))
            }
            if let line = view.plateLines["\(index):d\(di)"] { PlateLineView(line: line) }
        }
        ForEach(Array(source.bursts.enumerated()), id: \.offset) { ci, c in
            HStack(spacing: 8) {
                Text("Burst \(ci + 1)").font(.caption).foregroundStyle(.secondary).frame(width: 56, alignment: .leading)
                SetValueCell(value: c.r, decimals: 0, label: "Reps", compact: true) { v in
                    if let v { store.setBurst(entry, index, ci, v, side: side) }
                } step: { dir in store.setBurst(entry, index, ci, max(0, (c.r ?? 0) + Double(dir)), side: side) }
                Text("\(Int(c.restSec ?? 15))s").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Button { store.removeBurst(entry, index, ci) } label: { Image(systemName: "xmark") }
                    .buttonStyle(.borderless).accessibilityLabel(Text("Remove burst"))
            }
        }
    }
}

/// − value + : a number typed or stepped. What is typed is committed as it changes; the
/// stepper's step comes from the engine (load grid, reps, seconds).
struct SetValueCell: View {
    let value: Double?
    let decimals: Int
    let label: String
    var compact = false
    let commit: (Double?) -> Void
    let step: (Int) -> Void
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        HStack(spacing: 2) {
            Button { step(-1) } label: { Image(systemName: "minus").frame(width: 26, height: 34) }
                .buttonStyle(.borderless)
                .accessibilityLabel(Text("Decrease \(label)"))
            TextField("–", text: $text)
                .keyboardType(decimals > 0 ? .decimalPad : .numberPad)
                .multilineTextAlignment(.center)
                .font(.body.weight(.semibold)).monospacedDigit()
                .frame(minWidth: compact ? 40 : 46)
                .focused($focused)
                .onChange(of: text) { _, new in
                    guard focused else { return }
                    let t = new.replacingOccurrences(of: ",", with: ".")
                    if t.isEmpty { commit(nil) } else if let v = Double(t) { commit(v) }
                }
                .accessibilityLabel(Text(label))
            Button { step(1) } label: { Image(systemName: "plus").frame(width: 26, height: 34) }
                .buttonStyle(.borderless)
                .accessibilityLabel(Text("Increase \(label)"))
        }
        .padding(.horizontal, 2)
        .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 10))
        .frame(maxWidth: .infinity)
        .onAppear { text = format(value) }
        .onChange(of: value) { _, v in if !focused { text = format(v) } }
        .onChange(of: focused) { _, f in if !f { text = format(value) } }
    }

    private func format(_ v: Double?) -> String { v.map { Fmt.num($0, decimals: max(decimals, 2)) } ?? "" }
}

/// RIR / RPE: a tinted value that opens openGym's presets; picking one ticks the set.
struct EffortCell: View {
    let kind: String
    let value: Double?
    let heading: String
    let pick: (Double?) -> Void
    let step: (Int) -> Void

    private static let presets: [(rir: Double, feel: LocalizedStringKey, color: Color, tail: Bool)] = [
        (0, "Nothing left: went to failure", .purple, false),
        (0.5, "Maybe half a rep left", .red, false),
        (1, "One more rep in the tank", .orange, false),
        (2, "Two more reps", .yellow, false),
        (3, "Three more reps", .green, false),
        (4, "Easy: warm-up territory", Color(red: 0.14, green: 0.54, blue: 0.24), true),
    ]

    static func color(rir: Double?) -> Color? {
        guard let rir else { return nil }
        let bands: [(Double, Color)] = [(0.25, .purple), (0.75, .red), (1.5, .orange), (2.5, .yellow), (3.5, .green)]
        return bands.first { rir <= $0.0 }?.1 ?? Color(red: 0.14, green: 0.54, blue: 0.24)
    }

    private func scaled(_ rir: Double) -> Double { kind == "rpe" ? 10 - rir : rir }
    private var rir: Double? { value.map { kind == "rpe" ? 10 - $0 : $0 } }

    var body: some View {
        Menu {
            ForEach(Array(Self.presets.enumerated()), id: \.offset) { _, p in
                Button { pick(scaled(p.rir)) } label: {
                    Text("\(Fmt.num(scaled(p.rir)))\(p.tail ? "+" : "")  \(Text(p.feel))")
                }
            }
            if value != nil {
                Button("Clear", systemImage: "xmark", role: .destructive) { pick(nil) }
            }
        } label: {
            Text(value.map { Fmt.num($0) } ?? heading)
                .font(.subheadline.weight(.semibold)).monospacedDigit()
                .foregroundStyle(value == nil ? Color.secondary : Self.color(rir: rir) ?? .primary)
                .frame(width: 46, height: 34)
                .background((Self.color(rir: rir) ?? Color.gray).opacity(value == nil ? 0.12 : 0.22), in: .rect(cornerRadius: 10))
        }
        .accessibilityLabel(Text(heading))
        .accessibilityValue(Text(value.map { Fmt.num($0) } ?? String(localized: "Not rated")))
    }
}

struct PlateLineView: View {
    let line: PlateLine

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "circle.circle").font(.caption2)
            Text(line.text)
            if let short = line.short { Text("· \(short)").foregroundStyle(.orange) }
            Spacer()
            if !line.moves.isEmpty { Text(line.moves).monospacedDigit() }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.leading, 34)
    }
}
