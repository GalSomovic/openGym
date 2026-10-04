import SwiftUI

/// A labelled number with − and + and a field to type into: openGym's Stepper. What is typed
/// is kept as typed; the engine clamps it when the sheet is saved.
struct NumberStepper: View {
    let label: LocalizedStringKey
    @Binding var value: Double
    var step: Double = 1
    var decimals = 0
    var range: ClosedRange<Double> = 0...10_000
    var unit: String? = nil
    @FocusState private var focused: Bool
    @State private var text = ""

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button { set(value - step) } label: { Image(systemName: "minus") }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .disabled(value - step < range.lowerBound - 0.0001)
                .accessibilityLabel(Text("Decrease"))
            TextField("", text: $text)
                .keyboardType(decimals > 0 ? .decimalPad : .numberPad)
                .multilineTextAlignment(.center)
                .monospacedDigit()
                .frame(width: 64)
                .padding(.vertical, 6)
                .background(.quaternary.opacity(0.6), in: .rect(cornerRadius: 8))
                .focused($focused)
                .onChange(of: text) { _, new in
                    guard focused else { return }
                    let normalised = new.replacingOccurrences(of: ",", with: ".")
                    if let v = Double(normalised) { value = v }
                }
                .accessibilityLabel(Text(label))
            Button { set(value + step) } label: { Image(systemName: "plus") }
                .buttonStyle(.bordered)
                .buttonBorderShape(.circle)
                .disabled(value + step > range.upperBound + 0.0001)
                .accessibilityLabel(Text("Increase"))
            if let unit {
                Text(unit).foregroundStyle(.secondary).frame(minWidth: 24, alignment: .leading)
            }
        }
        .onAppear { text = Fmt.num(value, decimals: max(decimals, 2)) }
        .onChange(of: value) { _, v in if !focused { text = Fmt.num(v, decimals: max(decimals, 2)) } }
        .onChange(of: focused) { _, f in if !f { text = Fmt.num(value, decimals: max(decimals, 2)) } }
    }

    private func set(_ v: Double) {
        let rounded = (v / step).rounded() * step
        value = min(range.upperBound, max(range.lowerBound, (rounded * 1000).rounded() / 1000))
    }
}
