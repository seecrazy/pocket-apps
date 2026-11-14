import Foundation

enum FocusSessionTimeline {
    static func elapsedSeconds(session: FocusSessionModel, now: Date) -> Int {
        let reference: Date
        switch session.status {
        case FocusSessionStatus.paused.rawValue:
            reference = session.pausedAt ?? now
        case FocusSessionStatus.running.rawValue:
            reference = now
        default:
            return 0
        }

        let wallClockElapsed = max(0, reference.timeIntervalSince(session.startedAt))
        return max(0, Int(wallClockElapsed.rounded(.down)) - session.pausedSeconds)
    }

    static func remainingSeconds(session: FocusSessionModel, now: Date) -> Int {
        max(0, session.plannedMinutes * 60 - elapsedSeconds(session: session, now: now))
    }
}
