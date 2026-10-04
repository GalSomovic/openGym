import OpenGymCore
import SwiftUI

/// The finish summary (sheets.jsx FinishSummary): time, volume, sets and records.
struct FinishSummaryView: View {
    let summary: FinishSummary
    let close: () -> Void
    @Environment(GymStore.self) private var store
    @Environment(ExerciseCatalog.self) private var catalog

    var body: some View {
        let w = summary.workout
        let unit = store.pick("unit", as: String.self) ?? "kg"
        let sets = w.entries.reduce(0) { $0 + $1.sets.filter { $0.isDone && !$0.isWarmup }.count }
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: summary.prs.isEmpty ? "checkmark.seal.fill" : "trophy.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(summary.prs.isEmpty ? Color.accentColor : .yellow)
                    .symbolEffect(.bounce, value: summary.workout.id)
                    .padding(.top, 30)
                Text("Workout complete").font(.largeTitle.weight(.bold))
                Text(w.name ?? "").font(.title3).foregroundStyle(.secondary)
                HStack(spacing: 12) {
                    stat(w.durationSeconds.map { Self.duration($0) } ?? "—", "Time")
                    stat("\(Fmt.num((w.vol ?? 0).rounded(), decimals: 0)) \(unit)", "Volume")
                    stat("\(sets)", "Sets")
                }
                if !summary.prs.isEmpty || !summary.e1prs.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("New records").font(.headline)
                        ForEach(summary.prs, id: \.self) { id in
                            Label {
                                Text(catalog.name(id))
                            } icon: { Image(systemName: "trophy.fill").foregroundStyle(.yellow) }
                        }
                        ForEach(summary.e1prs, id: \.id) { r in
                            Label {
                                VStack(alignment: .leading) {
                                    Text(catalog.name(r.id))
                                    Text("Estimated 1RM \(Fmt.num(r.est)) \(unit)").font(.footnote).foregroundStyle(.secondary)
                                }
                            } icon: { Image(systemName: "chart.line.uptrend.xyaxis").foregroundStyle(Color.accentColor) }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.background.secondary, in: .rect(cornerRadius: 16))
                }
                Button(action: close) { Text("Done").frame(maxWidth: .infinity).fontWeight(.semibold) }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
            }
            .padding()
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("")
    }

    private func stat(_ value: String, _ label: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.title3.weight(.bold)).monospacedDigit().minimumScaleFactor(0.6).lineLimit(1)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.background.secondary, in: .rect(cornerRadius: 14))
    }

    static func duration(_ s: Double) -> String {
        let m = Int(s / 60)
        return m >= 60 ? "\(m / 60)h \(m % 60)m" : "\(m) min"
    }
}
