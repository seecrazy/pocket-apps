@testable import SoloGuard
import XCTest

final class SoloGuardLibraryTests: XCTestCase {
    func testCompletionAndMissedPreviousDay() {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
        let plan = CheckInPlanModel(title: "日常确认", reminderHour: 9, reminderMinute: 0)
        let library = SoloGuardLibrary(calendar: calendar)

        XCTAssertEqual(SoloGuardNotifications.id(for: plan.id), "sologuard.plan.\(plan.id.uuidString)")
        XCTAssertFalse(library.isCompleted(plan: plan, records: [], day: today))
        XCTAssertTrue(library.missedPreviousDay(plan: plan, records: [], today: today))

        guard let yesterday else {
            return XCTFail("Expected yesterday")
        }
        let records = [CheckInRecordModel(planID: plan.id, day: yesterday, completedAt: yesterday)]
        XCTAssertFalse(library.missedPreviousDay(plan: plan, records: records, today: today))
        XCTAssertTrue(library.isCompleted(plan: plan, records: records, day: yesterday))
    }
}
