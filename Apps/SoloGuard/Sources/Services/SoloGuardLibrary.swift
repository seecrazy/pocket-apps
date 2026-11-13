import Foundation

enum SoloGuardNotifications {
    static func id(for planID: UUID) -> String {
        "sologuard.plan.\(planID.uuidString)"
    }
}

struct SoloGuardLibrary {
    let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func isCompleted(
        plan: CheckInPlanModel,
        records: [CheckInRecordModel],
        day: Date
    ) -> Bool {
        let startOfDay = calendar.startOfDay(for: day)
        return records.contains {
            $0.planID == plan.id
                && calendar.isDate($0.day, inSameDayAs: startOfDay)
                && $0.completedAt != nil
        }
    }

    func missedPreviousDay(
        plan: CheckInPlanModel,
        records: [CheckInRecordModel],
        today: Date
    ) -> Bool {
        guard let yesterday = calendar.date(byAdding: .day, value: -1, to: calendar.startOfDay(for: today)) else {
            return false
        }
        return !isCompleted(plan: plan, records: records, day: yesterday)
    }
}
