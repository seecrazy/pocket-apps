@testable import SlowCard
import XCTest

final class SlowCardModelTests: XCTestCase {
    func testCardStatus() {
        let now = Date()
        let traveling = SlowCardModel(title: "A", body: "B", createdAt: now, unlockAt: now.addingTimeInterval(86400))
        let received = SlowCardModel(title: "A", body: "B", createdAt: now, unlockAt: now.addingTimeInterval(-1))

        XCTAssertEqual(traveling.status(now: now), .traveling)
        XCTAssertEqual(received.status(now: now), .received)
    }
}
