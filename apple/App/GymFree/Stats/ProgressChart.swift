import Charts
import OpenGymCore
import SwiftUI

/// openGym's LineChart in Swift Charts: one value per session, the dots filled by how hard the
/// session ran when it was rated (`m`), the selected point read out on touch.
struct ProgressChart: View {
    let points: [ChartPoint]
    let unit: String
    var color: Color = .accentColor
    /// RIR: fewer reps in reserve is harder, so the axis runs upside down.
    var inverted = false
    var height: CGFloat = 170

    @State private var selected: Date?

    var body: some View {
        // Inverted, the values are drawn negated and the axis labels show them back as they are.
        let sign: Double = inverted ? -1 : 1
        let values = points.map { $0.y * sign }
        let lo = values.min() ?? 0, hi = values.max() ?? 1
        let pad = max((hi - lo) * 0.12, hi == lo ? max(1, abs(hi) * 0.05) : 0)
        let domain = (lo - pad)...(hi + pad)
        let picked = selectedPoint
        Chart {
            ForEach(Array(points.enumerated()), id: \.offset) { _, p in
                LineMark(x: .value("Date", p.date), y: .value("Value", p.y * sign))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(color)
                if points.count < 60 {
                    PointMark(x: .value("Date", p.date), y: .value("Value", p.y * sign))
                        .symbolSize(p.m == nil ? 20 : 44)
                        .foregroundStyle(color.opacity(p.m.map { 0.25 + 0.75 * $0 } ?? 1))
                }
            }
            if let picked {
                RuleMark(x: .value("Date", picked.date))
                    .foregroundStyle(.secondary.opacity(0.4))
                    .annotation(position: .top, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                        VStack(spacing: 1) {
                            Text("\(Fmt.num(picked.y)) \(unit)").font(.caption.weight(.semibold))
                            Text(picked.date, format: .dateTime.day().month(.abbreviated).year(.twoDigits))
                                .font(.caption2).foregroundStyle(.secondary)
                            if let note = picked.note { Text(note).font(.caption2).foregroundStyle(.secondary) }
                        }
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(.regularMaterial, in: .rect(cornerRadius: 6))
                    }
            }
        }
        .chartYScale(domain: domain)
        .chartYAxis {
            AxisMarks(values: .automatic(desiredCount: 4)) { v in
                AxisGridLine()
                AxisValueLabel { if let y = v.as(Double.self) { Text(Fmt.num(y * sign)) } }
            }
        }
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
        .chartXSelection(value: $selected)
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Progress chart"))
        .accessibilityValue(Text(summary))
        .accessibilityIdentifier("progress.chart")
    }

    private var selectedPoint: ChartPoint? {
        guard let selected, !points.isEmpty else { return nil }
        return points.min { abs($0.date.timeIntervalSince(selected)) < abs($1.date.timeIntervalSince(selected)) }
    }

    private var summary: String {
        guard let first = points.first, let last = points.last else { return String(localized: "No data yet") }
        return "\(points.count) · \(Fmt.num(first.y)) → \(Fmt.num(last.y)) \(unit)"
    }
}
