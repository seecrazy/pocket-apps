import Foundation

struct MindfulDaySummary: Identifiable, Equatable {
    let day: Date
    let seconds: Int
    let hasPractice: Bool

    var id: Date {
        day
    }

    var minutes: Int {
        seconds / 60
    }
}

struct MindfulMinutesService {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func secondsToday(sessions: [PracticeSessionModel], today: Date = Date()) -> Int {
        let day = calendar.startOfDay(for: today)
        return sessions
            .filter { calendar.isDate($0.startedAt, inSameDayAs: day) }
            .reduce(0) { $0 + $1.mindfulSeconds }
    }

    func consecutiveDays(sessions: [PracticeSessionModel], today: Date = Date()) -> Int {
        let days = Set(sessions.map { calendar.startOfDay(for: $0.startedAt) })
        var streak = 0
        var day = calendar.startOfDay(for: today)

        while days.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }

        return streak
    }

    func lastDays(sessions: [PracticeSessionModel], today: Date = Date(), days: Int = 35) -> [MindfulDaySummary] {
        let end = calendar.startOfDay(for: today)
        guard days > 0, let start = calendar.date(byAdding: .day, value: -(days - 1), to: end) else { return [] }

        return (0 ..< days).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { return nil }
            let seconds = sessions
                .filter { calendar.isDate($0.startedAt, inSameDayAs: day) }
                .reduce(0) { $0 + $1.mindfulSeconds }
            return MindfulDaySummary(day: day, seconds: seconds, hasPractice: seconds >= 60)
        }
    }

    func weekTotalSeconds(sessions: [PracticeSessionModel], today: Date = Date()) -> Int {
        let end = calendar.startOfDay(for: today)
        guard let start = calendar.date(byAdding: .day, value: -6, to: end) else { return 0 }
        return sessions
            .filter { $0.startedAt >= start && $0.startedAt <= calendar.date(byAdding: .day, value: 1, to: end)! }
            .reduce(0) { $0 + $1.mindfulSeconds }
    }
}
