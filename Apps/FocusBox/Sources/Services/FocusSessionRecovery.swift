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
        guard session.status == FocusSessionStatus.running.rawValue else { return .none }
        let end = calendar.date(byAdding: .minute, value: session.plannedMinutes, to: session.startedAt) ?? session.startedAt
        let secondsLeft = Int(end.timeIntervalSince(now).rounded(.up))
        return secondsLeft > 0 ? .resume(secondsLeft: secondsLeft) : .complete(at: end)
    }
}
