import SwiftUI

/// A horizontal row of filter chips with an "All" chip first.
struct ChipRow: View {
    let allLabel: LocalizedStringKey
    let options: [String]
    @Binding var selection: String
    var title: (String) -> String = { $0.capitalizedWords }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(Text(allLabel), on: selection.isEmpty) { selection = "" }
                ForEach(options, id: \.self) { option in
                    chip(Text(title(option)), on: selection == option) { selection = option }
                }
            }
            .padding(.horizontal)
        }
        .scrollClipDisabled()
    }

    private func chip(_ label: Text, on: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            label
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .foregroundStyle(on ? Color.black : Color.primary)
                .background(on ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary.opacity(0.7)), in: .capsule)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
