import OpenGymCore
import SwiftUI

/// Home's week strip (views/Home.jsx): seven days with done, planned and rescheduled dots,
/// earlier and later weeks a tap away. A day opens its sheet: rest, another routine, or logging
/// a planned day that went by.
struct WeekStripView: View {
    @Binding var offset: Int
    @Environment(GymStore.self) private var store
    @Environment(TodayRouter.self) private var router

    var body: some View {
        if let strip = store.weekStrip(offset: offset, today: Day.today) {
            VStack(spacing: 8) {
                HStack {
                    Button { offset -= 1 } label: { Image(systemName: "chevron.backward") }
                        .accessibilityLabel(Text("Previous week"))
                    Spacer()
                    Text(strip.label).font(.subheadline.weight(.medium)).foregroundStyle(.secondary)
                        .onTapGesture { offset = 0 }
                    Spacer()
                    Button { offset += 1 } label: { Image(systemName: "chevron.forward") }
                        .accessibilityLabel(Text("Next week"))
                }
                .buttonStyle(.borderless)
                .font(.subheadline.weight(.semibold))
                HStack(spacing: 4) {
                    ForEach(strip.days) { day in
                        Button { router.sheet = .day(day.iso) } label: { cell(day) }
                            .buttonStyle(.plain)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(Text(Day.date(day.iso), format: .dateTime.weekday(.wide).day().month(.wide)))
                            .accessibilityValue(DayDot.label(day.dot) ?? Text(""))
                            .accessibilityAddTraits(day.today ? .isSelected : [])
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func cell(_ day: StripDay) -> some View {
        VStack(spacing: 4) {
            Text(day.label).font(.caption2.weight(.medium)).foregroundStyle(.secondary)
            Text("\(day.num)")
                .font(.callout.weight(day.today ? .bold : .regular))
                .monospacedDigit()
                .foregroundStyle(day.today ? Color.black : .primary)
                .frame(width: 32, height: 32)
                .background(day.today ? AnyShapeStyle(.tint) : AnyShapeStyle(.clear), in: .circle)
            DayDot(kind: day.dot)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
    }
}
