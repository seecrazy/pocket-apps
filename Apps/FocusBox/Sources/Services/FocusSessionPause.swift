import Foundation

enum FocusSessionPause {
    static func totalPausedSeconds(current: Int, pausedAt: Date, resumedAt: Date) -> Int {
        let delta = max(0, resumedAt.timeIntervalSince(pausedAt))
        return current + Int(delta.rounded(.up))
    }
}
