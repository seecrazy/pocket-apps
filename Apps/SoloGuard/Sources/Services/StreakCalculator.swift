import Foundation

struct StreakCalculator {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func streak(for planID: UUID, records: [CheckInRecordModel], today: Date) -> Int {
        let completedDays = Set(
            records
                .filter { $0.planID == planID && $0.completedAt != nil }
                .map { calendar.startOfDay(for: $0.day) }
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
