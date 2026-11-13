@testable import PocketUI
import SwiftUI
import XCTest

final class PrimaryButtonTests: XCTestCase {
    func testButtonCanBeCreated() {
        let button = PrimaryButton("确认") {}
        XCTAssertNotNil(button)
    }
}
