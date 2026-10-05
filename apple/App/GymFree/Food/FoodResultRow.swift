import SwiftUI

/// One food in the Add food search: its name, and energy and protein per 100 g.
struct FoodResultRow: View {
    let name: String
    let kcal: Double
    let protein: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(name).foregroundStyle(.primary).lineLimit(2)
            Text("\(Int(kcal.rounded())) kcal · \(protein.formatted(.number.precision(.fractionLength(0...1)))) g protein per 100 g")
                .font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(.rect)
    }
}
