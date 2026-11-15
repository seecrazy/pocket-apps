@testable import AtEase
import XCTest

@MainActor
final class SubscriptionServiceTests: XCTestCase {
    func testInitLoadsCachedSubscription() {
        let cache = InMemorySubscriptionCache()
        cache.save(
            CachedSubscriptionState(
                state: .subscribed,
                expiresAt: Date(timeIntervalSince1970: 1_900_000_000),
                cachedAt: Date(timeIntervalSince1970: 1_800_000_000),
                lastProductID: "annual"
            )
        )

        let service = AtEaseSubscriptionService(provider: MockSubscriptionProvider(), cache: cache)

        XCTAssertTrue(service.isSubscribed)
        XCTAssertEqual(service.expiresAt, Date(timeIntervalSince1970: 1_900_000_000))
    }

    func testRefreshUpdatesAndCachesNotSubscribed() async {
        let cache = InMemorySubscriptionCache()
        cache.save(CachedSubscriptionState(state: .subscribed, cachedAt: Date()))
        let provider = MockSubscriptionProvider(entitlement: .notSubscribed)
        let service = AtEaseSubscriptionService(provider: provider, cache: cache)

        await service.refresh()

        XCTAssertFalse(service.isSubscribed)
        XCTAssertNil(service.errorMessage)
        XCTAssertEqual(cache.saved?.state, .notSubscribed)
    }

    func testPurchaseErrorKeepsCachedStateAndShowsMessage() async {
        let cache = InMemorySubscriptionCache()
        cache.save(CachedSubscriptionState(state: .subscribed, cachedAt: Date()))
        let provider = MockSubscriptionProvider(entitlement: .subscribed, purchaseError: .storeUnavailable)
        let service = AtEaseSubscriptionService(provider: provider, cache: cache)

        await service.purchase(
            SubscriptionProduct(id: "monthly", displayName: "月度", displayPrice: "¥18", offerLabel: nil)
        )

        XCTAssertTrue(service.isSubscribed)
        XCTAssertEqual(service.errorMessage, SubscriptionError.storeUnavailable.errorDescription)
        XCTAssertEqual(cache.saved?.state, .subscribed)
    }

    func testRestoreSubscribedUpdatesStateAndCache() async {
        let cache = InMemorySubscriptionCache()
        let provider = MockSubscriptionProvider(entitlement: .subscribed)
        let service = AtEaseSubscriptionService(provider: provider, cache: cache)

        await service.restore()

        XCTAssertTrue(service.isSubscribed)
        XCTAssertEqual(service.errorMessage, "已恢复订阅。")
        XCTAssertEqual(cache.saved?.state, .subscribed)
    }

    func testRestoreWithoutEntitlementShowsNeutralMessage() async {
        let cache = InMemorySubscriptionCache()
        let provider = MockSubscriptionProvider(entitlement: .notSubscribed)
        let service = AtEaseSubscriptionService(provider: provider, cache: cache)

        await service.restore()

        XCTAssertFalse(service.isSubscribed)
        XCTAssertEqual(service.errorMessage, "没有找到可恢复的订阅。")
    }

    func testEntryRuleFollowsThirdSessionThreshold() {
        XCTAssertFalse(SubscriptionEntryRule.shouldShowEntry(afterSessionCount: 0))
        XCTAssertFalse(SubscriptionEntryRule.shouldShowEntry(afterSessionCount: 2))
        XCTAssertTrue(SubscriptionEntryRule.shouldShowEntry(afterSessionCount: 3))
        XCTAssertTrue(SubscriptionEntryRule.shouldShowEntry(afterSessionCount: 10))
    }
}

private final class InMemorySubscriptionCache: SubscriptionStateStoring {
    private(set) var saved: CachedSubscriptionState?

    func load() -> CachedSubscriptionState? {
        saved
    }

    func save(_ state: CachedSubscriptionState) {
        saved = state
    }
}

private struct MockSubscriptionProvider: SubscriptionStoreProviding {
    var entitlement: AtEaseSubscriptionState
    var purchaseError: SubscriptionError?

    init(
        entitlement: AtEaseSubscriptionState = .notSubscribed,
        purchaseError: SubscriptionError? = nil
    ) {
        self.entitlement = entitlement
        self.purchaseError = purchaseError
    }

    func products() async throws -> [SubscriptionProduct] {
        []
    }

    func purchase(productID: String) async throws -> AtEaseSubscriptionState {
        if let purchaseError {
            throw purchaseError
        }
        return entitlement
    }

    func restore() async throws -> AtEaseSubscriptionState {
        entitlement
    }

    func refreshEntitlement() async throws -> AtEaseSubscriptionState {
        entitlement
    }
}
