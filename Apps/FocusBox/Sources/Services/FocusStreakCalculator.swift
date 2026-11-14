import Foundation

struct FocusStreakCalculator {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func streak(sessions: [FocusSessionModel], today: Date) -> Int {
        let completedDays = Set(
            sessions
                .filter { $0.status == FocusSessionStatus.completed.rawValue }
                .map { calendar.startOfDay(for: $0.startedAt) }
        )

        var streak = 0
        var day = calendar.startOfDay(for: today)

        while completedDays.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }

        return streak
    }
}
