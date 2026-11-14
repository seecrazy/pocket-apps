@testable import AmbientLog
import XCTest

final class AudioLevelAnalyzerTests: XCTestCase {
    func testNormalizesPowerToUnitInterval() {
        XCTAssertEqual(AudioLevelAnalyzer.normalizePower(-160), 0, accuracy: 0.001)
        XCTAssertEqual(AudioLevelAnalyzer.normalizePower(-80), 0.5, accuracy: 0.001)
        XCTAssertEqual(AudioLevelAnalyzer.normalizePower(0), 1, accuracy: 0.001)
        XCTAssertEqual(AudioLevelAnalyzer.normalizePower(-200), 0, accuracy: 0.001)
    }

    func testAverageAndPeakPower() {
        let powers: [Double] = [-100, -50, -20]
        XCTAssertEqual(AudioLevelAnalyzer.averagePower(powers), -56.666, accuracy: 0.01)
        XCTAssertEqual(AudioLevelAnalyzer.peakPower(powers), -20)
    }

    func testDownsampleUsesPeakPerBucket() {
        let powers: [Double] = Array(repeating: -90, count: 50) + Array(repeating: -10, count: 50)
        let downsampled = AudioLevelAnalyzer.downsample(powers, maximumPoints: 2)
        XCTAssertEqual(downsampled, [-90, -10])
    }
}
