import SwiftUI

/// Routine icons (openGym lib/glyphs.js). The profile stores openGym's icon key, or a legacy
/// emoji from before its redesign; both resolve to an SF Symbol.
enum Glyphs {
    static let groups: [(key: LocalizedStringResource, items: [String])] = [
        ("Strength", ["figureStrength", "arm", "abs", "legs", "pullup"]),
        ("Equipment", ["dumbbell", "barbell", "kettlebell", "plate", "machine"]),
        ("Cardio", ["figureRun", "bike", "swim", "boxing", "timer"]),
        ("Recovery", ["stretch", "moon", "heart", "flame", "bolt"]),
    ]
    static let defaultKey = "figureStrength"

    private static let symbols: [String: String] = [
        "figureStrength": "figure.strengthtraining.traditional", "arm": "figure.arms.open",
        "abs": "figure.core.training", "legs": "figure.step.training", "pullup": "figure.climbing",
        "dumbbell": "dumbbell.fill", "barbell": "figure.strengthtraining.functional",
        "kettlebell": "figure.cross.training", "plate": "circle.circle.fill", "machine": "gearshape.2.fill",
        "figureRun": "figure.run", "bike": "figure.outdoor.cycle", "swim": "figure.pool.swim",
        "boxing": "figure.boxing", "timer": "timer", "stretch": "figure.flexibility",
        "moon": "moon.fill", "heart": "heart.fill", "flame": "flame.fill", "bolt": "bolt.fill",
        "trophy": "trophy.fill", "medal": "medal.fill", "crown": "crown.fill", "flag": "flag.fill",
        "star": "star.fill", "target": "target", "shield": "shield.fill",
    ]
    private static let legacy: [String: String] = [
        "💪": "arm", "🦾": "arm", "🫸": "figureStrength", "🫷": "pullup",
        "🏋️": "dumbbell", "🏋": "dumbbell", "🏋️‍♀️": "dumbbell", "🦵": "legs", "🍑": "legs",
        "🔥": "flame", "⚡": "bolt", "💥": "bolt", "🧨": "bolt", "😤": "flame",
        "🏃": "figureRun", "🏃‍♀️": "figureRun", "🚴": "bike", "🏊": "swim",
        "🤸": "stretch", "🧘": "stretch", "🧘‍♀️": "stretch", "🥊": "boxing", "🧗": "pullup",
        "⛰️": "figureRun", "🏔️": "figureRun", "🚀": "bolt", "🎯": "target", "🏆": "trophy",
        "🥇": "medal", "⭐": "star", "🌟": "star", "👑": "crown", "🛡️": "shield", "⚔️": "shield",
        "❤️‍🔥": "heart", "🦍": "kettlebell", "🐂": "barbell", "🐻": "kettlebell", "🦁": "boxing",
        "🐺": "figureRun", "🦈": "swim", "🤖": "machine",
    ]

    static func key(_ stored: String?) -> String {
        guard let stored, !stored.isEmpty else { return defaultKey }
        if symbols[stored] != nil { return stored }
        if let k = legacy[stored] { return k }
        let base = String(stored.unicodeScalars.filter { $0 != "\u{FE0F}" && $0 != "\u{200D}" }.prefix(1))
        return legacy[base] ?? defaultKey
    }

    static func symbol(_ stored: String?) -> String { symbols[key(stored)] ?? "figure.strengthtraining.traditional" }
}

struct RoutineIcon: View {
    let emoji: String?
    var size: CGFloat = 34

    var body: some View {
        Image(systemName: Glyphs.symbol(emoji))
            .font(.system(size: size * 0.5, weight: .semibold))
            .foregroundStyle(.tint)
            .frame(width: size, height: size)
            .background(.tint.opacity(0.15), in: .rect(cornerRadius: size * 0.28))
            .accessibilityHidden(true)
    }
}
