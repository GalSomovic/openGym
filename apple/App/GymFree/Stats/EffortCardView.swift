import OpenGymCore
import SwiftUI

/// Stats.jsx EffortCard: how close to failure the training ran, with how much of it was rated,
/// week by week, and where the sets land on the scale.
struct EffortCardView: View {
    @Environment(GymStore.self) private var store
    @AppStorage("gf.effortWindow") private var days = 90

    var body: some View {
        if let e = store.effortCard(days: days) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 6) {
                    Text(e.title).font(.headline)
                    Text("· \(e.subtitle)").font(.subheadline).foregroundStyle(.secondary)
                }
                Picker("Period", selection: $days) {
                    ForEach(e.windows, id: \.label) { w in Text(w.label).tag(Int(w.value.number ?? 90)) }
                }
                .pickerStyle(.segmented)
                if e.rated == 0 {
                    Text(e.empty).font(.subheadline).foregroundStyle(.secondary)
                } else {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(e.average).font(.title2.weight(.bold)).monospacedDigit()
                            Text(e.averageLabel).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(e.hard).font(.title2.weight(.bold)).foregroundStyle(.yellow).monospacedDigit()
                            Text(e.hardLabel).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                    Text(e.coverage).font(.caption).foregroundStyle(.secondary)
                    if let off = e.off { Text(off).font(.caption).foregroundStyle(.yellow) }
                    if e.weeks.count > 1 {
                        Text(e.weeksTitle).font(.caption.weight(.semibold)).foregroundStyle(.secondary).textCase(.uppercase)
                        ProgressChart(points: e.weeks.map { ChartPoint(t: $0.t, d: nil, y: $0.y, m: nil, note: $0.note) },
                                      unit: e.scale, color: .yellow, inverted: e.invert, height: 130)
                    }
                    Text(e.binsTitle).font(.caption.weight(.semibold)).foregroundStyle(.secondary).textCase(.uppercase)
                    ForEach(Array(e.bins.enumerated()), id: \.offset) { _, b in
                        HStack(spacing: 8) {
                            Text(b.label).font(.subheadline).frame(width: 64, alignment: .leading)
                            GeometryReader { geo in
                                Capsule().fill(.quaternary)
                                    .overlay(alignment: .leading) {
                                        Capsule().fill(b.hard ? Color.yellow : Color.secondary)
                                            .frame(width: max(b.n > 0 ? 4 : 0, geo.size.width * b.frac))
                                    }
                            }
                            .frame(height: 6)
                            Text(b.value).font(.caption).foregroundStyle(.secondary).monospacedDigit()
                                .frame(width: 64, alignment: .trailing)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    Text(e.footer).font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
}
