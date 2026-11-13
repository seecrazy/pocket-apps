@testable import PocketCore
import XCTest

final class KeyValueStoreTests: XCTestCase {
    func testUserDefaultsRoundTrip() throws {
        let suiteName = "PocketCoreTests-\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        let store = UserDefaultsStore(defaults: defaults)

        store.set(true, forKey: "enabled")
        store.set("hello", forKey: "title")
        store.set(42, forKey: "count")

        XCTAssertTrue(store.bool(forKey: "enabled"))
        XCTAssertEqual(store.string(forKey: "title"), "hello")
        XCTAssertEqual(store.integer(forKey: "count"), 42)

        store.removeObject(forKey: "title")
        XCTAssertNil(store.string(forKey: "title"))
    }
}
