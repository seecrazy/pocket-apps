@testable import AmbientLog
import XCTest

final class AudioRecordingTimerTests: XCTestCase {
    func testFormatsElapsedSeconds() {
        XCTAssertEqual(AudioRecordingTimer.format(seconds: 0), "00:00")
        XCTAssertEqual(AudioRecordingTimer.format(seconds: 65), "01:05")
        XCTAssertEqual(AudioRecordingTimer.format(seconds: 3725), "01:02:05")
    }
}
