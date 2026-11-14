import ActivityKit
import Foundation

struct BreathActivityAttributes: ActivityAttributes, Codable, Hashable, Sendable {
    struct ContentState: Codable, Hashable, Sendable {
        var phaseTitle: String
        var progress: Double
        var remainingSeconds: Int
        var isPaused: Bool
    }

    var patternTitle: String
}
