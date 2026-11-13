@testable import TabStash
import XCTest

final class TabStashTests: XCTestCase {
    func testTabURLParsing() {
        let collectionID = UUID()
        let tab = StashedTabModel(
            title: "Swift",
            urlString: "https://swift.org",
            collectionID: collectionID,
            lastModifiedAt: Date()
        )

        XCTAssertEqual(tab.url?.absoluteString, "https://swift.org")
    }
}
