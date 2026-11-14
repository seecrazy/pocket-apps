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
            category: "城市",
            startedAt: Date(),
            duration: 20,
            fileURLString: "/tmp/cafe.m4a"
        )

        XCTAssertEqual(AmbientRecordingLibrary.filtered([rain, cafe], query: ""), [rain, cafe])
        XCTAssertEqual(AmbientRecordingLibrary.filtered([rain, cafe], query: "  café  ", category: "全部"), [cafe])
        XCTAssertTrue(AmbientRecordingLibrary.filtered([rain, cafe], query: "sea", category: "全部").isEmpty)
        XCTAssertEqual(AmbientRecordingLibrary.filtered([rain, cafe], query: "", category: "自然"), [rain])
        XCTAssertEqual(AmbientRecordingLibrary.filtered([rain, cafe], query: "", category: "城市"), [cafe])
        XCTAssertEqual(AmbientRecordingLibrary.filtered([rain, cafe], query: "", category: "夜晚").isEmpty, true)
    }
}
