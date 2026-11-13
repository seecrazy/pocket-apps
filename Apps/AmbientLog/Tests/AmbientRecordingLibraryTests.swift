@testable import AmbientLog
import XCTest

final class AmbientRecordingLibraryTests: XCTestCase {
    func testSearchIsTrimmedAndCaseInsensitive() {
        let rain = AmbientRecordingModel(
            title: "雨声",
            startedAt: Date(),
            duration: 10,
            fileURLString: "/tmp/rain.m4a"
        )
        let cafe = AmbientRecordingModel(
            title: "Café Noise",
            startedAt: Date(),
            duration: 20,
            fileURLString: "/tmp/cafe.m4a"
        )

        XCTAssertEqual(AmbientRecordingLibrary.filtered([rain, cafe], query: ""), [rain, cafe])
        XCTAssertEqual(AmbientRecordingLibrary.filtered([rain, cafe], query: "  café  "), [cafe])
        XCTAssertTrue(AmbientRecordingLibrary.filtered([rain, cafe], query: "sea").isEmpty)
    }
}
