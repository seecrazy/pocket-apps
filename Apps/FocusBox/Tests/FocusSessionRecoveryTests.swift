@testable import FocusBox
import XCTest

final class FocusSessionRecoveryTests: XCTestCase {
    func testResumesRunningSession() throws {
        let calendar = Calendar.current
        let now = Date()
        let startedAt = try XCTUnwrap(calendar.date(byAdding: .minute, value: -5, to: now))
        let session = FocusSessionModel(startedAt: startedAt, plannedMinutes: 25)

        XCTAssertEqual(
            FocusSessionRecovery.decision(session: session, calendar: calendar, now: now),
            .resume(secondsLeft: 20 * 60)
        )
    }

    func testCompletesExpiredSession() throws {
        let calendar = Calendar.current
        let now = Date()
        let startedAt = try XCTUnwrap(calendar.date(byAdding: .minute, value: -26, to: now))
        let end = try XCTUnwrap(calendar.date(byAdding: .minute, value: 25, to: startedAt))
        let session = FocusSessionModel(startedAt: startedAt, plannedMinutes: 25)

        XCTAssertEqual(
            FocusSessionRecovery.decision(session: session, calendar: calendar, now: now),
            .complete(at: end)
        )
    }

    func testPausedSessionKeepsRemainingTimeFrozen() throws {
        let calendar = Calendar.current
        let now = Date()
        let startedAt = try XCTUnwrap(calendar.date(byAdding: .minute, value: -5, to: now))
        let pausedAt = try XCTUnwrap(calendar.date(byAdding: .minute, value: -1, to: now))
        let session = FocusSessionModel(
            startedAt: startedAt,
            plannedMinutes: 25,
            pausedAt: pausedAt,
            pausedSeconds: 0,
            status: FocusSessionStatus.paused.rawValue
        )

        XCTAssertEqual(
            FocusSessionRecovery.decision(session: session, calendar: calendar, now: now),
            .resume(secondsLeft: 21 * 60)
        )
    }
}
