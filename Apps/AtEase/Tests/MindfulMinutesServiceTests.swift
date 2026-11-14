@testable import AtEase
import XCTest

final class MindfulMinutesServiceTests: XCTestCase {
    private let calendar = Calendar(identifier: .gregorian)

    func testSecondsTodayIgnoresOtherDays() throws {
        let service = MindfulMinutesService(calendar: calendar)
        let today = try XCTUnwrap(calendar.date(byAdding: .minute, value: -2, to: Date()))
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: today))
        let sessions = [
            PracticeSessionModel(kind: .breath, startedAt: today, mindfulSeconds: 90),
            PracticeSessionModel(kind: .timer, startedAt: yesterday, mindfulSeconds: 300),
        ]

        XCTAssertEqual(service.secondsToday(sessions: sessions, today: today), 90)
    }

    func testConsecutiveDaysCountsTodayBackward() throws {
        let service = MindfulMinutesService(calendar: calendar)
        let today = try XCTUnwrap(calendar.date(byAdding: .minute, value: -1, to: Date()))
        let yesterday = try XCTUnwrap(calendar.date(byAdding: .day, value: -1, to: today))
        let sessions = [
            PracticeSessionModel(kind: .breath, startedAt: today, mindfulSeconds: 60),
            PracticeSessionModel(kind: .timer, startedAt: yesterday, mindfulSeconds: 60),
        ]

        XCTAssertEqual(service.consecutiveDays(sessions: sessions, today: today), 2)
    }

    func testLastDaysMarksSixtySecondsAsPractice() throws {
        let service = MindfulMinutesService(calendar: calendar)
        let today = try XCTUnwrap(calendar.date(byAdding: .minute, value: -1, to: Date()))
        let summaries = service.lastDays(sessions: [], today: today, days: 35)

        XCTAssertEqual(summaries.count, 35)
        XCTAssertFalse(try XCTUnwrap(summaries.last?.hasPractice))
    }
}
