import PocketCore
@testable import PocketTestKit
import XCTest

final class TestSupportTests: XCTestCase {
    func testFixedDateProviderReturnsFixedDate() {
        let date = Date(timeIntervalSince1970: 0)
        XCTAssertEqual(FixedDateProvider(date: date).now(), date)
    }

    func testInMemoryKeyValueStore() {
        let store = InMemoryKeyValueStore()
        store.set(true, forKey: "enabled")
        store.set("value", forKey: "name")
        store.set(7, forKey: "count")

        XCTAssertTrue(store.bool(forKey: "enabled"))
        XCTAssertEqual(store.string(forKey: "name"), "value")
        XCTAssertEqual(store.integer(forKey: "count"), 7)
    }

    func testInMemoryNotificationScheduler() async throws {
        let scheduler = InMemoryNotificationScheduler()
        let date = Date(timeIntervalSince1970: 100)

        try await scheduler.scheduleDailyReminder(
            id: "sologuard.plan.1",
            hour: 9,
            minute: 0,
            title: "签到",
            body: "确认今天正常"
        )
        try await scheduler.scheduleAt(
            id: "slowcard.card.1",
            date: date,
            title: "明信片到达",
            body: "可以打开了"
        )

        XCTAssertEqual(scheduler.dailyNotificationIDs(), ["sologuard.plan.1"])
        XCTAssertEqual(scheduler.datedNotificationIDs(), ["slowcard.card.1"])

        await scheduler.cancel(ids: ["sologuard.plan.1"])
        XCTAssertTrue(scheduler.dailyNotificationIDs().isEmpty)
    }
}
