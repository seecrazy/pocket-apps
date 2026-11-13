@testable import FocusBox
import XCTest

final class FocusStatsCalculatorTests: XCTestCase {
    func testCompletedMinutesToday() throws {
        let calendar = Calendar.current
        let today = try XCTUnwrap(calendar.date(byAdding: .minute, value: -1, to: Date()))
        let sessions = [
            FocusSessionModel(startedAt: today, plannedMinutes: 25, completedAt: today, status: "completed"),
            FocusSessionModel(startedAt: today, plannedMinutes: 45, completedAt: today, status: "abandoned"),
        ]

        XCTAssertEqual(FocusStatsCalculator(calendar: calendar).completedMinutesToday(sessions: sessions, today: today), 25)
    }
}
