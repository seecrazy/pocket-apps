@testable import SoloGuard
import XCTest

final class StreakCalculatorTests: XCTestCase {
    func testCountsConsecutiveDays() throws {
        let calendar = Calendar(identifier: .gregorian)
        let today = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 11, day: 14)))
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: today))
        let planID = UUID()

        let records = [
            CheckInRecordModel(planID: planID, day: yesterday, completedAt: yesterday),
            CheckInRecordModel(planID: planID, day: today, completedAt: today),
        ]

        XCTAssertEqual(StreakCalculator(calendar: calendar).streak(for: planID, records: records, today: today), 2)
    }
}
