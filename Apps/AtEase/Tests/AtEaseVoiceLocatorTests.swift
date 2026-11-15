@testable import AtEase
import XCTest

final class AtEaseVoiceLocatorTests: XCTestCase {
    func testBreathPhaseAssetNamesAreStable() {
        XCTAssertEqual(
            AtEaseVoiceLocator.assetName(for: .inhale(seconds: 4)),
            "voice-breath-inhale"
        )
        XCTAssertEqual(
            AtEaseVoiceLocator.assetName(for: .hold(seconds: 7)),
            "voice-breath-hold"
        )
        XCTAssertEqual(
            AtEaseVoiceLocator.assetName(for: .exhale(seconds: 8)),
            "voice-breath-exhale"
        )
    }

    func testContentStepAssetNameUsesStableIDs() {
        XCTAssertEqual(
            AtEaseVoiceLocator.contentStepName(contentID: "micro-rest-60", stepID: "breathe"),
            "voice-micro-rest-60-breathe"
        )
    }

    func testMissingGeneratedVoiceReturnsNilAndFallsBackToSystemSpeech() {
        XCTAssertNil(
            AtEaseVoiceLocator.url(
                forContentID: "missing-content",
                stepID: "missing-step"
            )
        )
    }
}
