import Charts
import OpenGymCore
import SwiftUI

extension WeightCard {
    /// bwDeltaColor: a change toward the goal is good, away from it bad, without one neutral.
    static func color(_ tone: String) -> Color {
        switch tone {
        case "good": .accentColor
        case "bad": .red
        default: .secondary
        }
    }
}

/// Home's body weight card: the latest weigh-in, how it moved, the goal, the curve.
struct WeightCardView: View {
    let card: WeightCard
    @Environment(GymStore.self) private var store
    @Environment(TodayRouter.self) private var router

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Body weight").font(.headline)
                Spacer()
                Button { router.sheet = .goal } label: {
                    Label { Text(card.goal.map { Fmt.num($0) } ?? String(localized: "Goal")) } icon: { Image(systemName: "target") }
                }
                .foregroundStyle(card.goal != nil ? Color.yellow : Color.accentColor)
                Button { router.sheet = .logWeight } label: { Label("Log", systemImage: "plus") }
                    .accessibilityIdentifier("weight.log")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            if let last = card.last {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(Text(Fmt.num(last.w)).font(.largeTitle.weight(.bold)).monospacedDigit()) \(Text(card.unit).font(.body).foregroundStyle(.secondary))")
                    if let delta = card.delta, let text = card.deltaText {
                        Label(text, systemImage: delta > 0 ? "arrow.up" : "arrow.down")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(WeightCard.color(card.tone))
                    }
                    Spacer()
                    Text(last.date).font(.subheadline).foregroundStyle(.tertiary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("weight.latest")
                if let goal = card.goalText {
                    Label(goal, systemImage: "target").font(.subheadline).foregroundStyle(.yellow)
                }
                WeightChart(points: Array(store.weightSeries().suffix(30)), goal: card.goal, unit: card.unit, height: 120)
                Button { router.show(.weight) } label: {
                    HStack(spacing: 4) { Text("All weigh-ins"); Image(systemName: "chevron.forward") }
                        .font(.subheadline)
                }
                .buttonStyle(.borderless)
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else {
                Text(card.empty).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

/// A line through the weigh-ins, with the goal as a dashed rule.
struct WeightChart: View {
    let points: [WeightPoint]
    let goal: Double?
    let unit: String
    var height: CGFloat = 180

    var body: some View {
        let values = points.map(\.w) + (goal.map { [$0] } ?? [])
        let lo = (values.min() ?? 0) - 1, hi = (values.max() ?? 1) + 1
        Chart {
            ForEach(points, id: \.d) { p in
                LineMark(x: .value("Date", Day.date(p.d)), y: .value("Weight", p.w))
                    .interpolationMethod(.monotone)
                    .foregroundStyle(Color.accentColor)
                if points.count < 40 {
                    PointMark(x: .value("Date", Day.date(p.d)), y: .value("Weight", p.w))
                        .symbolSize(18)
                        .foregroundStyle(Color.accentColor)
                }
            }
            if let goal {
                RuleMark(y: .value("Goal", goal))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundStyle(.yellow)
                    .annotation(position: .top, alignment: .leading) {
                        Text("\(Fmt.num(goal)) \(unit)").font(.caption2).foregroundStyle(.yellow)
                    }
            }
        }
        .chartYScale(domain: lo...hi)
        .chartXAxis { AxisMarks(values: .automatic(desiredCount: 4)) }
        .frame(height: height)
        .accessibilityLabel(Text("Body weight chart"))
    }
}

/// sheets.jsx WeighIns, with the chart's range: every weigh-in, week by week, each week under its
/// mean and how far that moved from the week before.
struct WeightView: View {
    enum Range: String, CaseIterable, Identifiable {
        case month = "1M", quarter = "3M", year = "1Y", all = "All"
        var id: String { rawValue }
        var label: LocalizedStringKey { LocalizedStringKey(rawValue) }
        var start: Date? {
            let cal = Calendar.current
            switch self {
            case .month: return cal.date(byAdding: .month, value: -1, to: .now)
            case .quarter: return cal.date(byAdding: .month, value: -3, to: .now)
            case .year: return cal.date(byAdding: .year, value: -1, to: .now)
            case .all: return nil
            }
        }
    }

    @Environment(GymStore.self) private var store
    @Environment(TodayRouter.self) private var router
    @AppStorage("gf.weightRange") private var range: Range = .quarter
    @State private var deleting: WeighInRow?

    var body: some View {
        let card = store.weightCard()
        let data = store.weighIns()
        List {
            if let data, data.count > 0 {
                Section {
                    Picker("Range", selection: $range) {
                        ForEach(Range.allCases) { r in Text(r.label).tag(r) }
                    }
                    .pickerStyle(.segmented)
                    let since = range.start.map { Fmt.todayISO($0) } ?? ""
                    WeightChart(points: store.weightSeries().filter { $0.d >= since }, goal: card?.goal, unit: card?.unit ?? "kg")
                    if let goal = card?.goalText {
                        Label(goal, systemImage: "target").font(.subheadline).foregroundStyle(.yellow)
                    }
                } footer: {
                    Text(data.title)
                }
                ForEach(data.weeks) { week in
                    Section {
                        ForEach(week.entries, id: \.d) { b in
                            HStack {
                                Text(b.date).foregroundStyle(.secondary)
                                Spacer()
                                Text(b.text).fontWeight(.semibold).monospacedDigit()
                            }
                            .swipeActions {
                                Button("Delete", systemImage: "trash", role: .destructive) { deleting = b }
                            }
                        }
                    } header: {
                        HStack(spacing: 8) {
                            Text(week.title)
                            Spacer()
                            if let d = week.delta, let text = week.deltaText {
                                Label(text, systemImage: d > 0 ? "arrow.up" : "arrow.down")
                                    .foregroundStyle(WeightCard.color(week.tone))
                            }
                            Text(week.average).textCase(nil)
                        }
                    }
                }
            } else {
                ContentUnavailableView {
                    Label("Weigh-ins", systemImage: "scalemass")
                } description: {
                    Text("No entries yet — log your weight to start the curve.")
                }
            }
        }
        .navigationTitle("Body weight")
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button { router.sheet = .goal } label: { Image(systemName: "target") }
                    .accessibilityLabel(Text("Target weight"))
                Button { router.sheet = .logWeight } label: { Image(systemName: "plus") }
                    .accessibilityLabel(Text("Log body weight"))
            }
        }
        // The full list asks first: months of history, scrolled through on a phone.
        .confirmationDialog("Delete weigh-in?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }),
                            titleVisibility: .visible, presenting: deleting) { b in
            Button("Delete", role: .destructive) { store.deleteWeighIn(b.d) }
        } message: { b in
            Text("\(b.date) · \(b.text)")
        }
    }
}
