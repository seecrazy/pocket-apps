@testable import AmbientLog
import XCTest

final class AudioLevelExplainerTests: XCTestCase {
    func testHumanReadableLevelNames() {
        XCTAssertEqual(AudioLevelExplainer.levelName(for: -160), "接近静音")
        XCTAssertEqual(AudioLevelExplainer.levelName(for: -80), "很安静")
        XCTAssertEqual(AudioLevelExplainer.levelName(for: -60), "安静")
        XCTAssertEqual(AudioLevelExplainer.levelName(for: -45), "一般说话")
        XCTAssertEqual(AudioLevelExplainer.levelName(for: -30), "较大声音")
        XCTAssertEqual(AudioLevelExplainer.levelName(for: -15), "很大声音")
        XCTAssertEqual(AudioLevelExplainer.levelName(for: -5), "接近满格")
    }

    func testExplanationClarifiesItIsNotSPL() {
        XCTAssertTrue(AudioLevelExplainer.explanation.contains("0 表示"))
        XCTAssertTrue(AudioLevelExplainer.explanation.contains("不是环境噪声的 dB SPL"))
    }
}
