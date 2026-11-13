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
}
