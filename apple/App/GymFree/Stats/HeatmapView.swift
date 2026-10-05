import OpenGymCore
import SwiftUI

/// Heatmap.jsx: the last 12 months, one column per week, each day shaded by the time or volume
/// trained. Scrolled to this week; a day with workouts opens them.
struct HeatmapView: View {
    let map: Heatmap
    let onMetric: (String) -> Void
    let onDay: (HeatCell) -> Void

    private let cell: CGFloat = 13
    private let gap: CGFloat = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Metric", selection: Binding(get: { map.metric }, set: { onMetric($0) })) {
                ForEach(map.options, id: \.label) { o in Text(o.label).tag(o.value.string ?? "time") }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier("heatmap.metric")
            HStack(alignment: .top, spacing: gap) {
                VStack(alignment: .trailing, spacing: gap) {
                    Text(" ").font(.system(size: 9))
                    ForEach(Array(map.dayLabels.enumerated()), id: \.offset) { _, label in
                        Text(label).font(.system(size: 9)).foregroundStyle(.secondary)
                            .frame(height: cell)
                    }
                }
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: gap) {
                            ForEach(Array(map.weeks.enumerated()), id: \.offset) { i, week in
                                VStack(spacing: gap) {
                                    Text(week.month).font(.system(size: 9)).foregroundStyle(.secondary)
                                        .fixedSize()
                                        .frame(width: cell, height: 11, alignment: .leading)
                                    ForEach(week.days) { day in
                                        square(day)
                                    }
                                }
                                .id(i)
                            }
                        }
                    }
                    .onAppear { proxy.scrollTo(map.weeks.count - 1, anchor: .trailing) }
                }
            }
            HStack(spacing: 4) {
                Spacer()
                Text(map.less)
                ForEach(0..<5) { level in
                    RoundedRectangle(cornerRadius: 2).fill(Self.color(level)).frame(width: 10, height: 10)
                }
                Text(map.more)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("heatmap")
    }

    @ViewBuilder
    private func square(_ day: HeatCell) -> some View {
        let shape = RoundedRectangle(cornerRadius: 2.5)
        let base = shape
            .fill(day.future ? Color.clear : Self.color(day.level))
            .overlay { if day.today { shape.stroke(Color.primary.opacity(0.7), lineWidth: 1.2) } }
            .frame(width: cell, height: cell)
        if day.n > 0 {
            Button { onDay(day) } label: { base }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(day.tip ?? day.iso))
        } else {
            base.accessibilityHidden(true)
        }
    }

    /// GitHub-style shading: empty, then four steps of the accent.
    static func color(_ level: Int) -> Color {
        switch level {
        case 0: Color.secondary.opacity(0.15)
        case 1: Color.accentColor.opacity(0.3)
        case 2: Color.accentColor.opacity(0.5)
        case 3: Color.accentColor.opacity(0.75)
        default: Color.accentColor
        }
    }
}
