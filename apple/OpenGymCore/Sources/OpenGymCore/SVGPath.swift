import CoreGraphics
import Foundation

/// SVG path data (`d`) into a CGPath: every command of SVG 1.1 (M L H V C S Q T A Z), absolute
/// and relative, with implicit repeats and the compact number syntax ("1.5.5", "-2-3", "1e-3",
/// arc flags written without separators). Arcs become cubic Béziers. Malformed data stops at
/// the first unreadable token, keeping what was drawn so far, as browsers do.
public enum SVGPath {
    public static func parse(_ d: String) -> CGPath {
        var parser = Parser(Array(d.utf8))
        return parser.run()
    }

    private struct Parser {
        let s: [UInt8]
        var i = 0
        let path = CGMutablePath()
        var current = CGPoint.zero
        var start = CGPoint.zero
        /// The last control point, for S/s (cubic) and T/t (quadratic) reflections.
        var lastCubic: CGPoint?
        var lastQuad: CGPoint?

        init(_ s: [UInt8]) { self.s = s }

        mutating func run() -> CGPath {
            var command: UInt8 = 0
            while true {
                skipSeparators()
                guard i < s.count else { break }
                let c = s[i]
                if isCommand(c) {
                    command = c
                    i += 1
                } else if command == 0 {
                    break   // numbers before any command
                }
                guard step(command) else { break }
                // After a moveto, further coordinate pairs are implicit linetos.
                if command == UInt8(ascii: "M") { command = UInt8(ascii: "L") }
                if command == UInt8(ascii: "m") { command = UInt8(ascii: "l") }
            }
            return path.copy() ?? path
        }

        /// One command's arguments. Returns false on malformed data.
        mutating func step(_ c: UInt8) -> Bool {
            let rel = c >= UInt8(ascii: "a")
            let base = rel ? current : .zero
            func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: base.x + x, y: base.y + y) }
            switch c | 0x20 {   // lowercased
            case UInt8(ascii: "m"):
                guard let x = number(), let y = number() else { return false }
                current = pt(x, y); start = current
                path.move(to: current)
                lastCubic = nil; lastQuad = nil
            case UInt8(ascii: "l"):
                guard let x = number(), let y = number() else { return false }
                lineTo(pt(x, y))
            case UInt8(ascii: "h"):
                guard let x = number() else { return false }
                lineTo(CGPoint(x: rel ? current.x + x : x, y: current.y))
            case UInt8(ascii: "v"):
                guard let y = number() else { return false }
                lineTo(CGPoint(x: current.x, y: rel ? current.y + y : y))
            case UInt8(ascii: "c"):
                guard let x1 = number(), let y1 = number(), let x2 = number(), let y2 = number(),
                      let x = number(), let y = number() else { return false }
                cubic(pt(x1, y1), pt(x2, y2), pt(x, y))
            case UInt8(ascii: "s"):
                guard let x2 = number(), let y2 = number(), let x = number(), let y = number() else { return false }
                let c1 = lastCubic.map { CGPoint(x: 2 * current.x - $0.x, y: 2 * current.y - $0.y) } ?? current
                cubic(c1, pt(x2, y2), pt(x, y))
            case UInt8(ascii: "q"):
                guard let x1 = number(), let y1 = number(), let x = number(), let y = number() else { return false }
                quad(pt(x1, y1), pt(x, y))
            case UInt8(ascii: "t"):
                guard let x = number(), let y = number() else { return false }
                let c1 = lastQuad.map { CGPoint(x: 2 * current.x - $0.x, y: 2 * current.y - $0.y) } ?? current
                quad(c1, pt(x, y))
            case UInt8(ascii: "a"):
                guard let rx = number(), let ry = number(), let rot = number(),
                      let large = flag(), let sweep = flag(), let x = number(), let y = number() else { return false }
                arc(rx: rx, ry: ry, rotation: rot, large: large, sweep: sweep, to: pt(x, y))
            case UInt8(ascii: "z"):
                path.closeSubpath()
                current = start
                lastCubic = nil; lastQuad = nil
                // Z takes no arguments: the next token must be a command.
                skipSeparators()
                if i < s.count, !isCommand(s[i]) { return false }
            default:
                return false
            }
            return true
        }

        mutating func lineTo(_ p: CGPoint) {
            ensureStarted()
            path.addLine(to: p); current = p
            lastCubic = nil; lastQuad = nil
        }

        mutating func cubic(_ c1: CGPoint, _ c2: CGPoint, _ p: CGPoint) {
            ensureStarted()
            path.addCurve(to: p, control1: c1, control2: c2)
            current = p; lastCubic = c2; lastQuad = nil
        }

        mutating func quad(_ c: CGPoint, _ p: CGPoint) {
            ensureStarted()
            path.addQuadCurve(to: p, control: c)
            current = p; lastQuad = c; lastCubic = nil
        }

        /// A drawing command with no moveto before it starts at the origin, as in SVG.
        mutating func ensureStarted() { if path.isEmpty { path.move(to: current) } }

        /// SVG's endpoint arc (F.6.5 of the SVG spec) as cubic segments of at most 90°.
        mutating func arc(rx rxIn: CGFloat, ry ryIn: CGFloat, rotation: CGFloat, large: Bool, sweep: Bool, to p: CGPoint) {
            ensureStarted()
            let p0 = current
            defer { current = p; lastCubic = nil; lastQuad = nil }
            var rx = abs(rxIn), ry = abs(ryIn)
            if p0 == p { return }
            if rx == 0 || ry == 0 { path.addLine(to: p); return }
            let phi = rotation * .pi / 180
            let cosPhi = cos(phi), sinPhi = sin(phi)
            let dx = (p0.x - p.x) / 2, dy = (p0.y - p.y) / 2
            let x1p = cosPhi * dx + sinPhi * dy
            let y1p = -sinPhi * dx + cosPhi * dy
            // Radii too small to reach are scaled up just enough (F.6.6).
            let lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry)
            if lambda > 1 { let k = sqrt(lambda); rx *= k; ry *= k }
            let num = rx * rx * ry * ry - rx * rx * y1p * y1p - ry * ry * x1p * x1p
            let den = rx * rx * y1p * y1p + ry * ry * x1p * x1p
            var coef = den == 0 ? 0 : sqrt(max(0, num / den))
            if large == sweep { coef = -coef }
            let cxp = coef * rx * y1p / ry
            let cyp = -coef * ry * x1p / rx
            let cx = cosPhi * cxp - sinPhi * cyp + (p0.x + p.x) / 2
            let cy = sinPhi * cxp + cosPhi * cyp + (p0.y + p.y) / 2
            func angle(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat {
                let a = atan2(ux * vy - uy * vx, ux * vx + uy * vy)
                return a
            }
            let theta1 = angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry)
            var delta = angle((x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry)
            if !sweep, delta > 0 { delta -= 2 * .pi }
            if sweep, delta < 0 { delta += 2 * .pi }
            let segments = max(1, Int(ceil(abs(delta) / (.pi / 2) - 1e-9)))
            let step = delta / CGFloat(segments)
            let k = 4 / 3 * tan(step / 4)
            func point(_ t: CGFloat) -> CGPoint {
                let x = rx * cos(t), y = ry * sin(t)
                return CGPoint(x: cx + cosPhi * x - sinPhi * y, y: cy + sinPhi * x + cosPhi * y)
            }
            func derivative(_ t: CGFloat) -> CGPoint {
                let x = -rx * sin(t), y = ry * cos(t)
                return CGPoint(x: cosPhi * x - sinPhi * y, y: sinPhi * x + cosPhi * y)
            }
            var t = theta1
            for n in 0..<segments {
                let t2 = t + step
                let a = point(t), b = point(t2), da = derivative(t), db = derivative(t2)
                let end = n == segments - 1 ? p : b
                path.addCurve(to: end,
                              control1: CGPoint(x: a.x + k * da.x, y: a.y + k * da.y),
                              control2: CGPoint(x: b.x - k * db.x, y: b.y - k * db.y))
                t = t2
            }
        }

        /* tokens */

        func isCommand(_ c: UInt8) -> Bool {
            switch c | 0x20 {
            case UInt8(ascii: "m"), UInt8(ascii: "l"), UInt8(ascii: "h"), UInt8(ascii: "v"), UInt8(ascii: "c"),
                 UInt8(ascii: "s"), UInt8(ascii: "q"), UInt8(ascii: "t"), UInt8(ascii: "a"), UInt8(ascii: "z"):
                // 'e'/'E' is never a command, so exponent letters are not mistaken for one.
                return true
            default: return false
            }
        }

        mutating func skipSeparators() {
            while i < s.count, s[i] == 0x20 || s[i] == 0x2C || s[i] == 0x09 || s[i] == 0x0A || s[i] == 0x0D { i += 1 }
        }

        /// An arc flag: a single 0 or 1, which may run straight into the next number.
        mutating func flag() -> Bool? {
            skipSeparators()
            guard i < s.count else { return nil }
            switch s[i] {
            case UInt8(ascii: "0"): i += 1; return false
            case UInt8(ascii: "1"): i += 1; return true
            default: return nil
            }
        }

        mutating func number() -> CGFloat? {
            skipSeparators()
            let begin = i
            if i < s.count, s[i] == UInt8(ascii: "+") || s[i] == UInt8(ascii: "-") { i += 1 }
            var digits = false, dot = false
            while i < s.count {
                let c = s[i]
                if c >= 0x30 && c <= 0x39 { digits = true; i += 1 }
                else if c == UInt8(ascii: "."), !dot { dot = true; i += 1 }
                else { break }
            }
            guard digits else { i = begin; return nil }
            if i < s.count, s[i] | 0x20 == UInt8(ascii: "e") {
                var j = i + 1
                if j < s.count, s[j] == UInt8(ascii: "+") || s[j] == UInt8(ascii: "-") { j += 1 }
                if j < s.count, s[j] >= 0x30 && s[j] <= 0x39 {
                    i = j
                    while i < s.count, s[i] >= 0x30 && s[i] <= 0x39 { i += 1 }
                }
            }
            guard let text = String(bytes: s[begin..<i], encoding: .ascii), let v = Double(text) else { i = begin; return nil }
            return CGFloat(v)
        }
    }
}

/// The body maps' outlines (body-paths.json, generated by apple/core/gen-body.mjs from openGym's
/// lib/body-paths.js — artwork from MuscleMap by Melih Colpan, MIT; see NOTICE.md): male and
/// female, front and back, one path list per body part. Parsed once, on first use.
public final class BodyGeometry: @unchecked Sendable {
    public struct View: @unchecked Sendable {
        /// The SVG viewBox: what the paths' coordinates are relative to.
        public let viewBox: CGRect
        /// Every body part's outline, combined into one path.
        public let parts: [String: CGPath]
    }

    public static let shared = BodyGeometry()

    /// `views["male"]?["front"]`.
    public let views: [String: [String: View]]

    init(bundle: Bundle = .module) {
        struct RawView: Decodable { let vb: String; let p: [String: [String]] }
        guard let url = bundle.url(forResource: "body-paths", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONDecoder().decode([String: [String: RawView]].self, from: data) else {
            views = [:]
            return
        }
        views = raw.mapValues { sides in
            sides.mapValues { v in
                let n = v.vb.split(separator: " ").compactMap { Double($0) }
                let box = n.count == 4 ? CGRect(x: n[0], y: n[1], width: n[2], height: n[3]) : .zero
                let parts = v.p.mapValues { list -> CGPath in
                    let combined = CGMutablePath()
                    for d in list { combined.addPath(SVGPath.parse(d)) }
                    return combined.copy() ?? combined
                }
                return View(viewBox: box, parts: parts)
            }
        }
    }

    /// One side of one body, falling back to the male outlines as openGym does.
    public func view(body: String, side: String) -> View? {
        (views[body] ?? views["male"])?[side]
    }
}
