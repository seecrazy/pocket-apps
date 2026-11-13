import Foundation

struct FocusStatsCalculator {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func completedMinutesToday(sessions: [FocusSessionModel], today: Date) -> Int {
        let day = calendar.startOfDay(for: today)
        return sessions
            .filter { $0.status == FocusSessionStatus.completed.rawValue && calendar.isDate($0.startedAt, inSameDayAs: day) }
            .reduce(0) { $0 + $1.plannedMinutes }
    }

    func completedMinutesForLastDays(sessions: [FocusSessionModel], today: Date, days: Int) -> [DailyFocusSummary] {
        let end = calendar.startOfDay(for: today)
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: end) ?? end

        return (0 ..< days).compactMap { offset in
            let day = calendar.date(byAdding: .day, value: offset, to: start)
            guard let day else { return nil }
            let minutes = sessions
                .filter { $0.status == FocusSessionStatus.completed.rawValue && calendar.isDate($0.startedAt, inSameDayAs: day) }
                .reduce(0) { $0 + $1.plannedMinutes }
            return DailyFocusSummary(day: day, minutes: minutes)
        }
    }
}

struct DailyFocusSummary: Identifiable {
    var day: Date
    var minutes: Int

    var id: Date {
        day
    }
}
