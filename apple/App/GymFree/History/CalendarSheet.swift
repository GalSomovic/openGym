import OpenGymCore
import SwiftUI

/// sheets.jsx Calendar: a month of training. A trained day opens its workout; any other day
/// opens the day sheet to plan or log it.
struct CalendarSheet: View {
    @Environment(GymStore.self) private var store
    @Environment(TodayRouter.self) private var router
    @Environment(\.dismiss) private var dismiss
    @State private var month: Date = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
    /// A day with more than one workout, showing them under the grid.
    @State private var picked: CalendarDay?

    private var ym: (Int, Int) {
        let c = Calendar.current.dateComponents([.year, .month], from: month)
        return (c.year ?? 2026, (c.month ?? 1) - 1)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let m = store.calendarMonth(year: ym.0, month: ym.1, today: Day.today) {
                    VStack(spacing: 14) {
                        HStack {
                            Button { shift(-1) } label: { Image(systemName: "chevron.backward") }
                                .accessibilityLabel(Text("Previous month"))
                            Spacer()
                            Text(m.title).font(.title3.weight(.semibold))
                            Spacer()
                            Button { shift(1) } label: { Image(systemName: "chevron.forward") }
                                .accessibilityLabel(Text("Next month"))
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.circle)
                        Text(m.summary).font(.subheadline).foregroundStyle(.secondary)
                        grid(m)
                        HStack(spacing: 16) {
                            legend("done", Text("Trained"))
                            legend("plan", Text("Planned"))
                            legend("ovr", Text("Rescheduled"))
                        }
                        .font(.caption).foregroundStyle(.secondary)
                        if let picked {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(Day.date(picked.iso), format: .dateTime.weekday(.wide).day().month()).font(.headline)
                                ForEach(store.historyRows().filter { picked.workouts.contains($0.key) }) { row in
                                    Button { router.show(.workout(row.key)) } label: { WorkoutRowView(row: row) }
                                        .buttonStyle(.plain)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.background.secondary, in: .rect(cornerRadius: 16))
                        }
                        Text("Tap a trained day for details · tap any other day to plan a session")
                            .font(.caption).foregroundStyle(.tertiary).multilineTextAlignment(.center)
                    }
                    .padding()
                }
            }
            .navigationTitle("Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
        }
        .presentationDetents([.large])
    }

    private func grid(_ m: CalendarMonth) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(m.headers.enumerated()), id: \.offset) { _, h in
                Text(h).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            }
            ForEach(0..<m.blanks, id: \.self) { i in Color.clear.frame(height: 44).id("blank\(i)") }
            ForEach(m.days) { day in
                Button { tap(day) } label: {
                    VStack(spacing: 3) {
                        Text("\(day.day)")
                            .font(.callout.weight(day.today ? .bold : .regular))
                            .monospacedDigit()
                            .foregroundStyle(day.today ? Color.black : .primary)
                            .frame(width: 34, height: 34)
                            .background(day.today ? AnyShapeStyle(.tint)
                                        : day.workouts.isEmpty ? AnyShapeStyle(.clear) : AnyShapeStyle(.tint.opacity(0.18)),
                                        in: .circle)
                        DayDot(kind: day.dot)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(Day.date(day.iso), format: .dateTime.weekday(.wide).day().month(.wide)))
                .accessibilityValue(DayDot.label(day.dot) ?? Text(""))
            }
        }
    }

    private func legend(_ kind: String, _ label: Text) -> some View {
        HStack(spacing: 5) { DayDot(kind: kind); label }
    }

    private func shift(_ by: Int) {
        picked = nil
        month = Calendar.current.date(byAdding: .month, value: by, to: month) ?? month
    }

    private func tap(_ day: CalendarDay) {
        switch day.workouts.count {
        case 0: router.sheet = .day(day.iso)
        case 1: router.show(.workout(day.workouts[0]))
        default: picked = day
        }
    }
}
