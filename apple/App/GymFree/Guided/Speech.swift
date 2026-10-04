import OpenGymCore
import Foundation

/// What guided mode says out loud, in the device language.
enum Speech {
    static func step(_ s: GuideStep, name: String, unit: String) -> String {
        var parts = [name]
        parts.append(s.warm ? String(localized: "Warm-up \(s.num) of \(s.count)") : String(localized: "Set \(s.num) of \(s.count)"))
        if s.side == "L" { parts.append(String(localized: "left side")) }
        if s.side == "R" { parts.append(String(localized: "right side")) }
        parts.append(target(s, unit: unit))
        return parts.filter { !$0.isEmpty }.joined(separator: ". ") + "."
    }

    static func target(_ s: GuideStep, unit: String) -> String {
        let weight = (s.w ?? 0) > 0 ? weightWords(s.w!, unit: unit) : nil
        if s.cardio {
            return String(localized: "\(Int(s.min ?? 0)) minutes")
        }
        if s.timed {
            let hold = String(localized: "Hold \(Int(s.sec ?? 0)) seconds")
            return weight.map { String(localized: "\(hold) with \($0)") } ?? hold
        }
        let reps = Int(s.r ?? 0)
        return weight.map { String(localized: "\(reps) reps at \($0)") } ?? String(localized: "\(reps) reps")
    }

    static func weightWords(_ w: Double, unit: String) -> String {
        let n = Fmt.num(w, decimals: 2)
        return unit == "lb" ? String(localized: "\(n) pounds") : String(localized: "\(n) kilos")
    }

    static func restStart(_ seconds: Double) -> String {
        let s = Int(seconds.rounded())
        return s >= 60 && s % 60 == 0
            ? String(localized: "Rest \(s / 60) minutes.")
            : String(localized: "Rest \(s) seconds.")
    }
}
