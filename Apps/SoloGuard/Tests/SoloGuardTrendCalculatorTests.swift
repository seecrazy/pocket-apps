@testable import SoloGuard
import XCTest

final class SoloGuardTrendCalculatorTests: XCTestCase {
    func testCountsCompletedRecordsForLastDays() {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)
        guard let yesterday, let twoDaysAgo else {
            return XCTFail("Expected previous days")
        }

        let records = [
            CheckInRecordModel(planID: UUID(), day: yesterday, completedAt: yesterday),
            CheckInRecordModel(planID: UUID(), day: yesterday, completedAt: yesterday),
            CheckInRecordModel(planID: UUID(), day: twoDaysAgo, completedAt: twoDaysAgo),
            CheckInRecordModel(planID: UUID(), day: today, completedAt: nil),
        ]

        let trend = SoloGuardTrendCalculator(calendar: calendar).dailySummaries(
            records: records,
            today: today,
            days: 14
        )

        XCTAssertEqual(trend.count, 14)
        XCTAssertEqual(trend[11].completedCount, 1)
        XCTAssertEqual(trend[12].completedCount, 2)
        XCTAssertEqual(trend[13].completedCount, 0)
    }
}
