@testable import AtEase
import XCTest

@MainActor
final class MeditationScriptPlayerTests: XCTestCase {
    func testPlaysThroughStepsAndCompletes() throws {
        let item = try makeItem()
        let player = MeditationScriptPlayer(content: item)

        player.start()
        XCTAssertEqual(player.status, .playing)
        XCTAssertEqual(player.currentStep?.id, "one")

        for _ in 0 ..< item.durationSeconds {
            player.advanceOneSecond()
        }

        XCTAssertEqual(player.status, .completed)
        XCTAssertEqual(player.completedSeconds, item.durationSeconds)
        XCTAssertEqual(player.currentStep?.id, "two")
    }

    func testPauseStopsProgress() throws {
        let item = try makeItem()
        let player = MeditationScriptPlayer(content: item)
        player.start()
        player.pause()
        player.advanceOneSecond()

        XCTAssertEqual(player.completedSeconds, 0)
        XCTAssertEqual(player.status, .paused)
    }

    func testOverallProgressIsFractionOfTotalDuration() throws {
        let item = try makeItem()
        let player = MeditationScriptPlayer(content: item)
        player.start()
        player.advanceOneSecond()

        XCTAssertEqual(player.overallProgress, 1.0 / 120.0, accuracy: 0.0001)
    }

    private func makeItem() throws -> MeditationContentItem {
        MeditationContentItem(
            id: "player-test",
            title: "Test",
            subtitle: "Sub",
            teacher: "At Ease",
            theme: .reset,
            durationSeconds: 120,
            audioKind: .scripted,
            isSubscriptionRequired: false,
            steps: [
                MeditationContentStep(id: "one", title: "One", text: "First", durationSeconds: 60, hapticEnabled: true),
                MeditationContentStep(id: "two", title: "Two", text: "Second", durationSeconds: 60, hapticEnabled: false),
            ]
        )
    }
}
