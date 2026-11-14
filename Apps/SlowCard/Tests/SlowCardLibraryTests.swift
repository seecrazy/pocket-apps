@testable import SlowCard
import XCTest

final class SlowCardLibraryTests: XCTestCase {
    func testFiltersIncludingArchive() {
        let now = Date()
        let traveling = SlowCardModel(title: "Traveling", body: "Body", createdAt: now, unlockAt: now.addingTimeInterval(86400))
        let received = SlowCardModel(title: "Received", body: "Body", createdAt: now, unlockAt: now.addingTimeInterval(-1))
        let favorite = SlowCardModel(
            title: "Favorite",
            body: "Body",
            createdAt: now,
            unlockAt: now.addingTimeInterval(-1),
            isFavorite: true
        )
        let cards = [traveling, received, favorite]

        XCTAssertEqual(SlowCardLibrary.filtered(cards, by: .all, now: now).count, 3)
        XCTAssertEqual(SlowCardLibrary.filtered(cards, by: .traveling, now: now), [traveling])
        XCTAssertEqual(SlowCardLibrary.filtered(cards, by: .received, now: now), [received, favorite])
        XCTAssertEqual(SlowCardLibrary.filtered(cards, by: .favorite, now: now), [favorite])
        XCTAssertEqual(SlowCardLibrary.filtered(cards, by: .archive, now: now), [received])
    }

    func testPromptsAreAvailable() {
        XCTAssertFalse(SlowCardPrompts.titles.isEmpty)
        XCTAssertTrue(SlowCardPrompts.titles.allSatisfy { !$0.isEmpty })
    }
}

final class SlowCardCountdownTests: XCTestCase {
    func testFormatsCountdown() {
        let now = Date()
        XCTAssertEqual(
            SlowCardLibrary.countdown(unlockAt: now.addingTimeInterval(86400 * 3), now: now).text,
            "3 天后到达"
        )
        XCTAssertEqual(
            SlowCardLibrary.countdown(unlockAt: now.addingTimeInterval(3600 * 2), now: now).text,
            "2 小时后到达"
        )
        XCTAssertEqual(
            SlowCardLibrary.countdown(unlockAt: now.addingTimeInterval(60 * 2), now: now).text,
            "2 分钟后到达"
        )
        XCTAssertEqual(SlowCardLibrary.countdown(unlockAt: now.addingTimeInterval(-1), now: now).text, "已到达")
    }
}
