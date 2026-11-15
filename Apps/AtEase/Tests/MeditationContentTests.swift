@testable import AtEase
import XCTest

final class MeditationContentTests: XCTestCase {
    private let loader = MeditationContentCatalogLoader()

    func testBundledCatalogLoadsAndIsValid() throws {
        let manifest = try loader.loadBundledCatalog()

        XCTAssertEqual(manifest.schemaVersion, 2)
        XCTAssertEqual(manifest.items.count, 8)
        XCTAssertEqual(manifest.items.filter { !$0.isSubscriptionRequired }.count, 5)
        XCTAssertEqual(manifest.items.filter(\.isSubscriptionRequired).count, 3)
        XCTAssertTrue(manifest.items.allSatisfy { $0.durationSeconds >= 60 })
        for item in manifest.items {
            let stepTotal = item.steps.reduce(0) { $0 + $1.durationSeconds }
            XCTAssertEqual(stepTotal, item.durationSeconds)
        }
    }

    func testRejectsUnsupportedSchemaVersion() throws {
        let manifest = try AtEaseContentManifest(
            schemaVersion: 3,
            items: [makeItem()]
        )

        XCTAssertThrowsError(try MeditationContentValidator.validate(manifest))
    }

    func testRejectsDuplicateContentIDs() throws {
        let item = try makeItem()
        let manifest = AtEaseContentManifest(schemaVersion: 2, items: [item, item])

        XCTAssertThrowsError(try MeditationContentValidator.validate(manifest))
    }

    func testRejectsStepDurationMismatch() throws {
        let item = try makeItem(steps: [
            MeditationContentStep(id: "step", title: "Step", text: "Text", durationSeconds: 30),
        ])
        let manifest = AtEaseContentManifest(schemaVersion: 2, items: [item])

        XCTAssertThrowsError(try MeditationContentValidator.validate(manifest))
    }

    private func makeItem(
        durationSeconds: Int = 60,
        steps: [MeditationContentStep]? = nil
    ) throws -> MeditationContentItem {
        let resolvedSteps = steps ?? [
            MeditationContentStep(id: "one", title: "One", text: "Text", durationSeconds: 30),
            MeditationContentStep(id: "two", title: "Two", text: "Text", durationSeconds: 30),
        ]

        return MeditationContentItem(
            id: "content-\(UUID().uuidString)",
            title: "Test",
            subtitle: "Sub",
            teacher: "At Ease",
            theme: .reset,
            durationSeconds: durationSeconds,
            audioKind: .scripted,
            isSubscriptionRequired: false,
            steps: resolvedSteps
        )
    }
}
