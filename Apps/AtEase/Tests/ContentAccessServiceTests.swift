@testable import AtEase
import XCTest

final class ContentAccessServiceTests: XCTestCase {
    private let service = MeditationContentAccessService()

    private func makeItem(id: String, requiresSubscription: Bool) -> MeditationContentItem {
        MeditationContentItem(
            id: id,
            title: id,
            subtitle: "",
            teacher: "",
            theme: .reset,
            durationSeconds: 60,
            audioKind: .scripted,
            isSubscriptionRequired: requiresSubscription,
            steps: [MeditationContentStep(id: "step", title: "练习", text: "保持觉察。", durationSeconds: 60)]
        )
    }

    func testFreeContentIsAlwaysUnlocked() {
        let item = makeItem(id: "free", requiresSubscription: false)

        XCTAssertTrue(service.canPlay(item, isSubscribed: false))
        XCTAssertTrue(service.canPlay(item, isSubscribed: true))
    }

    func testSubscriptionContentRequiresEntitlement() {
        let item = makeItem(id: "premium", requiresSubscription: true)

        XCTAssertFalse(service.canPlay(item, isSubscribed: false))
        XCTAssertTrue(service.canPlay(item, isSubscribed: true))
    }

    func testAllShowsFreeBeforeSubscriptionContent() {
        let manifest = AtEaseContentManifest(
            schemaVersion: 1,
            items: [
                makeItem(id: "premium-1", requiresSubscription: true),
                makeItem(id: "free-1", requiresSubscription: false),
                makeItem(id: "premium-2", requiresSubscription: true),
                makeItem(id: "free-2", requiresSubscription: false),
            ]
        )

        let items = service.visibleItems(
            from: manifest,
            filter: .all,
            favoriteContentIDs: [],
            isSubscribed: false
        )

        XCTAssertEqual(items.map(\.id), ["free-1", "free-2", "premium-1", "premium-2"])
    }

    func testFavoritesIncludeLockedSubscriptionContent() {
        let manifest = AtEaseContentManifest(
            schemaVersion: 1,
            items: [
                makeItem(id: "free", requiresSubscription: false),
                makeItem(id: "premium", requiresSubscription: true),
            ]
        )

        let items = service.visibleItems(
            from: manifest,
            filter: .favorites,
            favoriteContentIDs: ["premium"],
            isSubscribed: false
        )

        XCTAssertEqual(items.map(\.id), ["premium"])
        XCTAssertEqual(service.access(for: items[0], isSubscribed: false), .subscriptionRequired)
    }

    func testBundledCatalogHasFreeAndSubscriptionTiers() throws {
        let manifest = try MeditationContentCatalogLoader().loadBundledCatalog()

        XCTAssertEqual(manifest.items.filter { !$0.isSubscriptionRequired }.count, 5)
        XCTAssertEqual(manifest.items.filter(\.isSubscriptionRequired).count, 3)
    }
}
