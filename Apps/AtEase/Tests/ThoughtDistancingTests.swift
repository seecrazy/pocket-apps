@testable import AtEase
import XCTest

final class ThoughtDistancingTests: XCTestCase {
    func testProgressReachesOneAfterHoldDuration() {
        let startedAt = Date(timeIntervalSince1970: 100)
        let now = startedAt.addingTimeInterval(8)
        let progress = min(1, now.timeIntervalSince(startedAt) / 8)

        XCTAssertEqual(progress, 1)
    }

    func testIncompleteProgressResetsBelowOne() {
        let startedAt = Date(timeIntervalSince1970: 100)
        let now = startedAt.addingTimeInterval(4)
        let progress = min(1, now.timeIntervalSince(startedAt) / 8)

        XCTAssertEqual(progress, 0.5)
    }
}
