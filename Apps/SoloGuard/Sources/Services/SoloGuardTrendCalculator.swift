import Foundation

struct DailySoloGuardSummary: Identifiable, Equatable {
    let day: Date
    let completedCount: Int

    var id: Date {
        day
    }
}

struct SoloGuardTrendCalculator {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func dailySummaries(
        records: [CheckInRecordModel],
        today: Date,
        days: Int
    ) -> [DailySoloGuardSummary] {
        let end = calendar.startOfDay(for: today)
        guard days > 0, let start = calendar.date(byAdding: .day, value: -(days - 1), to: end) else {
            return []
        }

        return (0 ..< days).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else {
                return nil
            }
            let completedCount = records.filter { record in
                record.completedAt != nil && calendar.isDate(record.day, inSameDayAs: day)
            }.count
            return DailySoloGuardSummary(day: day, completedCount: completedCount)
        }
    }
}
