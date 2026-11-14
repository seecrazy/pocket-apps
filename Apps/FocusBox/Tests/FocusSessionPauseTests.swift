@testable import FocusBox
import XCTest

final class FocusSessionPauseTests: XCTestCase {
    func testAccumulatesPausedSeconds() {
        let pausedAt = Date(timeIntervalSince1970: 1000)
        let resumedAt = Date(timeIntervalSince1970: 1090)

        XCTAssertEqual(
            FocusSessionPause.totalPausedSeconds(
                current: 10,
                pausedAt: pausedAt,
                resumedAt: resumedAt
            ),
            100
        )
    }
}

final class FocusStreakCalculatorTests: XCTestCase {
    func testCountsConsecutiveCompletedDays() throws {
        let calendar = Calendar(identifier: .gregorian)
        let today = calendar.startOfDay(for: Date())
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: today))
        let twoDaysAgo = try XCTUnwrap(calendar.date(byAdding: .day, value: -2, to: today))

        let sessions = [
            FocusSessionModel(startedAt: today, plannedMinutes: 25, completedAt: today, status: "completed"),
            FocusSessionModel(startedAt: yesterday, plannedMinutes: 25, completedAt: yesterday, status: "completed"),
            FocusSessionModel(startedAt: twoDaysAgo, plannedMinutes: 25, completedAt: twoDaysAgo, status: "abandoned"),
        ]

        XCTAssertEqual(FocusStreakCalculator(calendar: calendar).streak(sessions: sessions, today: today), 2)
    }
}
