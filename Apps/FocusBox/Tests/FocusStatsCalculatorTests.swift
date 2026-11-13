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

    func testSevenDayTrendOnlyCountsCompletedSessions() {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)
        guard let yesterday else {
            return XCTFail("Expected yesterday")
        }
        let sessions = [
            FocusSessionModel(startedAt: yesterday, plannedMinutes: 30, completedAt: yesterday, status: "completed"),
            FocusSessionModel(startedAt: yesterday, plannedMinutes: 45, completedAt: yesterday, status: "abandoned"),
            FocusSessionModel(startedAt: today, plannedMinutes: 25, completedAt: today, status: "completed"),
        ]

        let trend = FocusStatsCalculator(calendar: calendar).completedMinutesForLastDays(
            sessions: sessions,
            today: today,
            days: 7
        )

        XCTAssertEqual(trend.count, 7)
        XCTAssertEqual(trend[5].minutes, 30)
        XCTAssertEqual(trend.last?.minutes, 25)
    }
}
