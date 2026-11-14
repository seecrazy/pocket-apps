import Foundation

enum FocusSessionRecovery {
    enum Decision: Equatable {
        case resume(secondsLeft: Int)
        case complete(at: Date)
        case none
    }

    static func decision(
        session: FocusSessionModel,
        calendar: Calendar = .current,
        now: Date
    ) -> Decision {
        switch session.status {
        case FocusSessionStatus.paused.rawValue:
            guard let pausedAt = session.pausedAt else {
                return .resume(secondsLeft: session.plannedMinutes * 60)
            }
            let elapsed = max(0, pausedAt.timeIntervalSince(session.startedAt) - Double(session.pausedSeconds))
            let secondsLeft = session.plannedMinutes * 60 - Int(elapsed.rounded(.up))
            return secondsLeft > 0 ? .resume(secondsLeft: secondsLeft) : .complete(at: pausedAt)
        case FocusSessionStatus.running.rawValue:
            let end = calendar.date(byAdding: .minute, value: session.plannedMinutes, to: session.startedAt) ?? session.startedAt
            let secondsLeft = Int(end.timeIntervalSince(now).rounded(.up))
            return secondsLeft > 0 ? .resume(secondsLeft: secondsLeft) : .complete(at: end)
        default:
            return .none
        }
    }
}
