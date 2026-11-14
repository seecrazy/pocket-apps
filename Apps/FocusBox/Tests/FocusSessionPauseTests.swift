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
