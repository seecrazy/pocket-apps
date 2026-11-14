@testable import FocusBox
import XCTest

final class FocusSessionTimelineTests: XCTestCase {
    func testRunningSessionUsesWallClock() throws {
        let now = Date()
        let startedAt = try XCTUnwrap(now.addingTimeInterval(-5 * 60))
        let session = FocusSessionModel(startedAt: startedAt, plannedMinutes: 25)

        XCTAssertEqual(FocusSessionTimeline.remainingSeconds(session: session, now: now), 20 * 60)
    }

    func testRunningSessionSubtractsPausedSeconds() throws {
        let now = Date()
        let startedAt = try XCTUnwrap(now.addingTimeInterval(-10 * 60))
        let session = FocusSessionModel(startedAt: startedAt, plannedMinutes: 25, pausedSeconds: 180)

        XCTAssertEqual(FocusSessionTimeline.remainingSeconds(session: session, now: now), 18 * 60)
    }

    func testPausedSessionFreezesAtPauseTime() throws {
        let now = Date()
        let startedAt = try XCTUnwrap(now.addingTimeInterval(-10 * 60))
        let pausedAt = try XCTUnwrap(now.addingTimeInterval(-2 * 60))
        let session = FocusSessionModel(
            startedAt: startedAt,
            plannedMinutes: 25,
            pausedAt: pausedAt,
            pausedSeconds: 60,
            status: FocusSessionStatus.paused.rawValue
        )

        XCTAssertEqual(FocusSessionTimeline.remainingSeconds(session: session, now: now), 18 * 60)
    }
}
