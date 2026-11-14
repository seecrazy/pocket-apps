@testable import AtEase
import XCTest

final class RecommendationEngineTests: XCTestCase {
    func testAgitatedMoodPrioritizesOneMinuteSOS() {
        let recommendations = RecommendationEngine().recommendations(for: 4)
        XCTAssertEqual(recommendations.first?.kind, .sos)
        XCTAssertEqual(recommendations.first?.minutes, 1)
    }

    func testCalmMoodIncludesNonUrgentOptions() {
        let recommendations = RecommendationEngine().recommendations(for: 0)
        XCTAssertEqual(recommendations.count, 3)
        XCTAssertFalse(recommendations.contains { $0.kind == .sos })
    }

    func testNeutralMoodIncludesShortReset() {
        let recommendations = RecommendationEngine().recommendations(for: 2)
        XCTAssertTrue(recommendations.contains { $0.kind == .sos && $0.minutes == 1 })
    }
}
