import ActivityKit
import Foundation

/// A GPS walk, run or ride on the Lock Screen and in the Dynamic Island: distance, pace (or
/// speed on a ride) and the moving time.
struct MotionActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// "2.34 km"
        var distance: String
        /// "5:41 /km" or "18.2 km/h"
        var detail: String
        /// Now minus the moving time: a clock counting up from here shows the moving time.
        var clockStart: Date
        /// Set while paused: the moving time, frozen.
        var pausedClock: String?
    }

    /// "walk", "run" or "cycle".
    var kind: String
    var name: String
    var startedAt: Date

    var symbol: String {
        switch kind {
        case "run": "figure.run"
        case "cycle": "figure.outdoor.cycle"
        default: "figure.walk"
        }
    }
}
