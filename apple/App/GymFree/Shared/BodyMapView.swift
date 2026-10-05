import OpenGymCore
import SwiftUI

/// openGym's BodyMap: front and back of a body, each muscle shaded 0–4. The outlines come from
/// BodyGeometry (openGym's body-paths, artwork from MuscleMap by Melih Colpan, MIT); which parts
/// are muscles, their names and the figure (Settings → Appearance → Body diagram) come from the
/// engine. With `onMuscle`, every muscle is a button of its exact shape.
struct BodyMapView: View {
    let levels: [String: Int]
    var palette: BodyPalette = .balance
    var selected: String? = nil
    /// nil reads the profile's choice ("male" or "female").
    var figure: String? = nil
    var onMuscle: ((String) -> Void)? = nil

    @Environment(GymStore.self) private var store

    var body: some View {
        let info = store.bodyInfo()
        let fig = figure ?? info?.body ?? "male"
        HStack(alignment: .top, spacing: 12) {
            ForEach(["front", "back"], id: \.self) { side in
                if let view = BodyGeometry.shared.view(body: fig, side: side) {
                    BodySide(view: view, key: "\(fig).\(side)", info: info, levels: levels, palette: palette,
                             selected: selected, onMuscle: onMuscle)
                        .aspectRatio(view.viewBox.width / max(1, view.viewBox.height), contentMode: .fit)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .modifier(MapAccessibility(interactive: onMuscle != nil, summary: summary(info)))
    }

    /// A map that cannot be tapped reads as one image: the muscles it shades, most first.
    private func summary(_ info: BodyInfo?) -> String {
        let names = (info?.muscles ?? []).filter { (levels[$0.slug] ?? 0) > 0 }
            .sorted { (levels[$0.slug] ?? 0) > (levels[$1.slug] ?? 0) }.map(\.name)
        return names.isEmpty ? String(localized: "No muscles worked") : names.joined(separator: ", ")
    }
}

private struct MapAccessibility: ViewModifier {
    let interactive: Bool
    let summary: String

    func body(content: Content) -> some View {
        if interactive {
            content.accessibilityElement(children: .contain).accessibilityIdentifier("bodymap")
        } else {
            content.accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Body map"))
                .accessibilityValue(Text(summary))
                .accessibilityIdentifier("bodymap")
        }
    }
}

/// The shade colours: openGym's .bm-m levels, and its fatigue and strength variants.
enum BodyPalette {
    case balance, fatigue, strength

    init(_ name: String) {
        switch name {
        case "fatigue": self = .fatigue
        case "strength": self = .strength
        default: self = .balance
        }
    }

    static let base = Color.secondary.opacity(0.3)
    static let silhouette = Color.primary.opacity(0.08)

    func color(_ level: Int) -> Color {
        switch self {
        case .fatigue:
            switch level {
            case 0: Self.base
            case 1: Color.yellow.opacity(0.35)
            case 2: Color.yellow
            case 3: Color.orange
            default: Color.red
            }
        case .balance, .strength:
            switch level {
            case 0: Self.base
            case 1: Color.accentColor.opacity(0.35)
            case 2: Color.accentColor.opacity(0.58)
            case 3: Color.accentColor.opacity(0.8)
            default: self == .strength ? Color.yellow : Color.accentColor
            }
        }
    }
}

/// One side of the body, drawn in its view box's coordinates scaled to fit.
private struct BodySide: View {
    let view: BodyGeometry.View
    let key: String
    let info: BodyInfo?
    let levels: [String: Int]
    let palette: BodyPalette
    let selected: String?
    let onMuscle: ((String) -> Void)?

    var body: some View {
        GeometryReader { geo in
            let scale = geo.size.width / max(1, view.viewBox.width)
            let box = view.viewBox
            ZStack(alignment: .topLeading) {
                PartShape(path: Self.silhouette(view, key: key, inert: info?.inert ?? []), box: box)
                    .fill(BodyPalette.silhouette)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .accessibilityHidden(true)
                ForEach(info?.muscles ?? []) { m in
                    if let path = view.parts[m.slug] {
                        let b = path.boundingBoxOfPath
                        muscle(m, path: path, bounds: b, scale: scale)
                            .frame(width: b.width * scale, height: b.height * scale)
                            .offset(x: (b.minX - box.minX) * scale, y: (b.minY - box.minY) * scale)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func muscle(_ m: BodyMuscle, path: CGPath, bounds: CGRect, scale: CGFloat) -> some View {
        let shape = PartShape(path: path, box: bounds)
        let filled = shape.fill(palette.color(levels[m.slug] ?? 0))
            .overlay { if selected == m.slug { shape.stroke(Color.primary, lineWidth: 2) } }
        if let onMuscle {
            let inside = Self.insidePoint(path, key: "\(key).\(m.slug)")
            filled
                .contentShape(shape)
                .onTapGesture { onMuscle(m.slug) }
                .accessibilityElement()
                .accessibilityLabel(Text(m.name))
                .accessibilityAddTraits(selected == m.slug ? [.isButton, .isSelected] : .isButton)
                .accessibilityIdentifier("muscle.\(m.slug)")
                .accessibilityActivationPoint(UnitPoint(x: (inside.x - bounds.minX) / max(1, bounds.width),
                                                        y: (inside.y - bounds.minY) / max(1, bounds.height)))
                .accessibilityAction { onMuscle(m.slug) }
        } else {
            filled.allowsHitTesting(false)
        }
    }

    /* caches: the geometry never changes, so these are worked out once per part */

    @MainActor private static var silhouettes: [String: CGPath] = [:]
    @MainActor private static var insides: [String: CGPoint] = [:]

    @MainActor static func silhouette(_ view: BodyGeometry.View, key: String, inert: [String]) -> CGPath {
        if let p = silhouettes[key] { return p }
        let combined = CGMutablePath()
        for slug in inert { if let p = view.parts[slug] { combined.addPath(p) } }
        let p = combined.copy() ?? combined
        silhouettes[key] = p
        return p
    }

    /// A point inside the part (its centre when that is inside, else the first grid point that
    /// is): where VoiceOver and UI tests activate it. A pair of pecs has its centre between them.
    @MainActor static func insidePoint(_ path: CGPath, key: String) -> CGPoint {
        if let p = insides[key] { return p }
        let b = path.boundingBoxOfPath
        var found = CGPoint(x: b.midX, y: b.midY)
        if !path.contains(found) {
            search: for fy in stride(from: 0.5, through: 0.95, by: 0.05) {
                for sy in [1.0, -1.0] {
                    for fx in stride(from: 0.05, through: 0.95, by: 0.05) {
                        let p = CGPoint(x: b.minX + b.width * fx, y: b.midY + sy * (fy - 0.5) * b.height)
                        if path.contains(p) { found = p; break search }
                    }
                }
            }
        }
        insides[key] = found
        return found
    }
}

/// A part's path, scaled from `box` (in the geometry's coordinates) to the frame it is given.
private struct PartShape: Shape {
    let path: Path
    let box: CGRect

    init(path: CGPath, box: CGRect) {
        self.path = Path(path)
        self.box = box
    }

    func path(in rect: CGRect) -> Path {
        guard box.width > 0, box.height > 0 else { return Path() }
        let s = min(rect.width / box.width, rect.height / box.height)
        let t = CGAffineTransform(translationX: rect.minX, y: rect.minY)
            .scaledBy(x: s, y: s)
            .translatedBy(x: -box.minX, y: -box.minY)
        return path.applying(t)
    }
}

/// The map's key: swatches with their labels ("Less ▢▢▢▢▢ More", "Fatigued ▢ Recovering ▢ Ready ▢").
struct BodyMapLegend: View {
    let items: [MapLegend]
    let palette: BodyPalette

    var body: some View {
        HStack(spacing: 4) {
            Spacer(minLength: 0)
            if items.count <= 3 {
                // Named bands: each label before its swatch.
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    Text(item.label).padding(.leading, 4)
                    swatch(item.level)
                }
            } else {
                // A scale: its two ends named.
                if let first = items.first, !first.label.isEmpty { Text(first.label) }
                ForEach(Array(items.enumerated()), id: \.offset) { _, item in swatch(item.level) }
                if let last = items.last, !last.label.isEmpty { Text(last.label) }
            }
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }

    private func swatch(_ level: Int) -> some View {
        RoundedRectangle(cornerRadius: 2).fill(palette.color(level)).frame(width: 11, height: 11)
    }
}
