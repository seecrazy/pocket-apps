@testable import AmbientLog
import XCTest

final class AmbientLogTests: XCTestCase {
    func testModelFileURL() {
        let url = FileManager.default.temporaryDirectory.appending(path: "test.m4a")
        let model = AmbientRecordingModel(
            title: "Test",
            startedAt: Date(),
            duration: 10,
            fileURLString: url.path
        )
        XCTAssertEqual(model.fileURL, url)
    }
}
