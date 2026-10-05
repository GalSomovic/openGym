import Foundation

// The bundled, offline food database: generic foods from USDA FoodData Central (Foundation Foods
// and SR Legacy, public domain), built by apple/mediatools/usda_foods.py into usda-foods.json.
// It only fills in per-100 g values; logging and all the math stay in apple/core/nutrition.js.
// Loaded once, indexed in memory, searched locally. No network calls.

struct USDAFood: Identifiable, Hashable, Sendable {
    struct Portion: Hashable, Sendable { var label: String; var grams: Double }
    var id: Int                 // FDC id
    var name: String
    var category: String
    var kcal: Double
    var p: Double
    var f: Double
    var c: Double               // available carbohydrate (fibre taken out), as on EU/UK labels
    var fiber: Double
    var common: Int             // > 0 for everyday foods, higher first
    var portions: [Portion]

    var source: String { "usda:\(id)" }
}

final class FoodDatabase: Sendable {
    static let shared = FoodDatabase()

    let foods: [USDAFood]
    let credit: String
    let release: String
    private let index: [Entry]

    private struct Entry: Sendable {
        var tokens: [String]
        var segments: [Int]     // which comma-separated part of the name each token is in
        var penalty: Double
        var length: Int
    }

    init(bundle: Bundle = .main) {
        var foods: [USDAFood] = []
        var credit = "U.S. Department of Agriculture, Agricultural Research Service. FoodData Central."
        var release = ""
        if let url = bundle.url(forResource: "usda-foods", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let doc = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            credit = doc["credit"] as? String ?? credit
            release = (doc["releases"] as? [String: String])?.sorted { $0.key < $1.key }.map { "\($0.key) \($0.value)" }.joined(separator: ", ") ?? ""
            let cats = doc["categories"] as? [String] ?? []
            for case let r as [Any] in doc["foods"] as? [Any] ?? [] where r.count >= 10 {
                let n = { (i: Int) in (r[i] as? NSNumber)?.doubleValue ?? 0 }
                let cat = Int(n(2))
                let portions = (r[9] as? [[Any]] ?? []).compactMap { p -> USDAFood.Portion? in
                    guard p.count == 2, let label = p[0] as? String, let g = (p[1] as? NSNumber)?.doubleValue else { return nil }
                    return .init(label: label, grams: g)
                }
                foods.append(USDAFood(id: Int(n(0)), name: r[1] as? String ?? "", category: cat < cats.count ? cats[cat] : "",
                                      kcal: n(3), p: n(4), f: n(5), c: n(6), fiber: n(7), common: Int(n(8)), portions: portions))
            }
        }
        self.foods = foods
        self.credit = credit
        self.release = release
        self.index = foods.map { food in
            var tokens: [String] = [], segments: [Int] = []
            for (s, part) in food.name.split(separator: ",").enumerated() {
                for t in Self.tokenize(String(part)) { tokens.append(t); segments.append(s) }
            }
            // Shorter names are usually the plainer food; everyday foods skip this (the list orders them).
            var penalty = food.common > 0 ? 0 : 0.15 * Double(tokens.count)
            if Self.niche.contains(food.category) { penalty += 3 }
            return Entry(tokens: tokens, segments: segments, penalty: penalty, length: food.name.count)
        }
    }

    /// Foods matching every word of the query (word prefixes, plurals and a few synonyms), best first.
    func search(_ query: String, limit: Int = 40) -> [USDAFood] {
        let words = Self.queryWords(query)
        guard !words.isEmpty else { return [] }
        var scored: [(Double, Int)] = []
        for (i, e) in index.enumerated() {
            var total = 0.0
            var matchedAll = true
            for alternatives in words {
                var best = -1.0
                for (j, t) in e.tokens.enumerated() {
                    for w in alternatives where t.hasPrefix(w) {
                        var s = t.count == w.count ? 3.0 : 1.5
                        s += e.segments[j] == 0 ? 2 : (e.segments[j] == 1 ? 1 : 0)
                        if j == 0 { s += 1 }
                        best = max(best, s)
                    }
                }
                if best < 0 { matchedAll = false; break }
                total += best
            }
            guard matchedAll else { continue }
            let common = foods[i].common
            if common > 0 { total += 10 + Double(common) / 4 }
            scored.append((total - e.penalty, i))
        }
        scored.sort { $0.0 != $1.0 ? $0.0 > $1.0 : index[$0.1].length < index[$1.1].length }
        return scored.prefix(limit).map { foods[$0.1] }
    }

    /* ------------------------------ words ------------------------------ */

    /// Restaurant and regional dishes are rarely what someone typing "chicken" means.
    private static let niche: Set<String> = ["Restaurant Foods", "Fast Foods", "American Indian/Alaska Native Foods"]

    private static let stopWords: Set<String> = ["and", "with", "of", "the", "a", "in", "or"]

    /// British and everyday names → USDA's words. Phrases first, then single words.
    private static let phrases: [(String, String)] = [
        ("semi skimmed", "reduced fat"), ("skimmed milk", "milk nonfat"), ("skim milk", "milk nonfat"),
        ("minced beef", "beef ground"), ("beef mince", "beef ground"), ("bell pepper", "peppers sweet"),
        ("spring onion", "onions spring"), ("sweet corn", "corn sweet"), ("whey protein", "whey"),
        ("jacket potato", "potatoes baked"),
    ]
    private static let synonyms: [String: [String]] = {
        let raw: [String: [String]] = [
        "yoghurt": ["yogurt"], "courgette": ["zucchini"], "aubergine": ["eggplant"], "prawn": ["shrimp"],
        "mince": ["ground"], "minced": ["ground"], "rocket": ["arugula"], "porridge": ["oat"], "oatmeal": ["oat"],
        "capsicum": ["pepper"], "crisps": ["potato chips"], "sweetcorn": ["corn sweet"], "beetroot": ["beet"],
        "swede": ["rutabaga"], "pitta": ["pita"], "houmous": ["hummus"], "hummous": ["hummus"], "humous": ["hummus"],
        "soya": ["soy"], "ketchup": ["catsup"], "cornflakes": ["corn flakes"], "skimmed": ["nonfat"], "skim": ["nonfat"],
        "fibre": ["fiber"], "wholemeal": ["whole wheat"], "wholewheat": ["whole wheat"], "tinned": ["canned"],
        ]
        return Dictionary(raw.map { (stem(fold($0.key)), $0.value) }, uniquingKeysWith: { a, _ in a })
    }()

    /// Each query word with its alternatives; a multi-word synonym becomes extra required words.
    static func queryWords(_ query: String) -> [[String]] {
        var q = " " + fold(query).replacingOccurrences(of: "-", with: " ") + " "
        for (from, to) in phrases { q = q.replacingOccurrences(of: " \(from) ", with: " \(to) ") }
        var out: [[String]] = []
        for w in tokenize(q) where !stopWords.contains(w) {
            if let alt = synonyms[w] {
                let parts = alt.flatMap { tokenize($0) }
                if parts.count == 1 { out.append([w, parts[0]]) } else { out.append(contentsOf: parts.map { [$0] }) }
            } else {
                out.append([w])
            }
        }
        return out
    }

    static func fold(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: nil).lowercased()
    }

    /// Lowercase words, singular ("eggs" → "egg", "berries" → "berry", "potatoes" → "potato").
    static func tokenize(_ s: String) -> [String] {
        fold(s).split { !($0.isLetter || $0.isNumber || $0 == "%") }.map { stem(String($0)) }.filter { !$0.isEmpty }
    }

    static func stem(_ w: String) -> String {
        if w.count > 4, w.hasSuffix("ies") { return String(w.dropLast(3)) + "y" }
        if w.count > 4, w.hasSuffix("oes") { return String(w.dropLast(2)) }
        if w.count > 3, w.hasSuffix("s"), !w.hasSuffix("ss") { return String(w.dropLast()) }
        return w
    }
}
