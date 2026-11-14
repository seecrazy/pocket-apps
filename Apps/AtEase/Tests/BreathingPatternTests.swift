@testable import AtEase
import XCTest

final class BreathingPatternTests: XCTestCase {
    func testRelaxingPatternUses478() {
        let pattern = BreathingPattern.relaxing
        XCTAssertEqual(pattern.phases.map(\.seconds), [4, 7, 8])
        XCTAssertEqual(pattern.phases.map(\.title), ["吸气", "屏息", "呼气"])
    }

    func testBoxPatternHasEqualPhases() {
        XCTAssertEqual(BreathingPattern.box.phases.map(\.seconds), [4, 4, 4, 4])
    }

    func testSOSIsShort() {
        XCTAssertLessThanOrEqual(BreathingPattern.sos.phases.reduce(0) { $0 + $1.seconds }, 10)
    }
}
