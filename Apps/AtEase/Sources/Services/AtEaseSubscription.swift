import Foundation
import StoreKit

enum AtEaseSubscriptionState: String, Codable, Equatable {
    case notSubscribed
    case subscribed
}

struct CachedSubscriptionState: Codable, Equatable {
    var state: AtEaseSubscriptionState
    var expiresAt: Date?
    var cachedAt: Date
    var lastProductID: String?

    init(
        state: AtEaseSubscriptionState = .notSubscribed,
        expiresAt: Date? = nil,
        cachedAt: Date = Date(),
        lastProductID: String? = nil
    ) {
        self.state = state
        self.expiresAt = expiresAt
        self.cachedAt = cachedAt
        self.lastProductID = lastProductID
    }
}

protocol SubscriptionStateStoring {
    func load() -> CachedSubscriptionState?
    func save(_ state: CachedSubscriptionState)
}

struct UserDefaultsSubscriptionCache: SubscriptionStateStoring {
    private let defaults: UserDefaults
    private let key = "atease.cachedSubscriptionState"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> CachedSubscriptionState? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(CachedSubscriptionState.self, from: data)
    }

    func save(_ state: CachedSubscriptionState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        defaults.set(data, forKey: key)
    }
}

struct SubscriptionProduct: Identifiable, Equatable {
    let id: String
    let displayName: String
    let displayPrice: String
    let offerLabel: String?
}

enum SubscriptionError: Error, LocalizedError, Equatable {
    case productNotFound
    case unverifiedPurchase
    case storeUnavailable

    var errorDescription: String? {
        switch self {
        case .productNotFound: return "暂时找不到订阅产品。"
        case .unverifiedPurchase: return "购买无法验证，没有更改订阅状态。"
        case .storeUnavailable: return "暂时无法连接 App Store。"
        }
    }
}

protocol SubscriptionStoreProviding {
    func products() async throws -> [SubscriptionProduct]
    func purchase(productID: String) async throws -> AtEaseSubscriptionState
    func restore() async throws -> AtEaseSubscriptionState
    func refreshEntitlement() async throws -> AtEaseSubscriptionState
}

struct StoreKitSubscriptionProvider: SubscriptionStoreProviding {
    static let monthlyID = "com.pocketapps.atease.subscription.monthly"
    static let annualID = "com.pocketapps.atease.subscription.annual"

    private var productIDs: [String] {
        [Self.monthlyID, Self.annualID]
    }

    func products() async throws -> [SubscriptionProduct] {
        let products = try await Product.products(for: productIDs)
        guard !products.isEmpty else { throw SubscriptionError.productNotFound }

        return products
            .sorted { lhs, rhs in
                let lhsIsAnnual = lhs.id == Self.annualID
                let rhsIsAnnual = rhs.id == Self.annualID
                return lhsIsAnnual && !rhsIsAnnual
            }
            .map { product in
                SubscriptionProduct(
                    id: product.id,
                    displayName: product.displayName,
                    displayPrice: product.displayPrice,
                    offerLabel: Self.offerLabel(for: product)
                )
            }
    }

    func purchase(productID: String) async throws -> AtEaseSubscriptionState {
        guard let product = try await Product.products(for: [productID]).first else {
            throw SubscriptionError.productNotFound
        }

        let result = try await product.purchase()
        switch result {
        case let .success(verification):
            switch verification {
            case let .verified(transaction):
                await transaction.finish()
                return try await refreshEntitlement()
            case .unverified:
                throw SubscriptionError.unverifiedPurchase
            }
        case .userCancelled, .pending:
            return try await refreshEntitlement()
        @unknown default:
            throw SubscriptionError.storeUnavailable
        }
    }

    func restore() async throws -> AtEaseSubscriptionState {
        try await AppStore.sync()
        return try await refreshEntitlement()
    }

    func refreshEntitlement() async throws -> AtEaseSubscriptionState {
        for await verification in Transaction.currentEntitlements {
            guard case let .verified(transaction) = verification else { continue }

            let isValidProduct = productIDs.contains(transaction.productID)
            let isNotRevoked = transaction.revocationDate == nil
            let isNotExpired = transaction.expirationDate.map { $0 > Date() } ?? true

            if isValidProduct, isNotRevoked, isNotExpired {
                return .subscribed
            }
        }
        return .notSubscribed
    }

    private static func offerLabel(for product: Product) -> String? {
        guard let offer = product.subscription?.introductoryOffer else { return nil }

        if offer.paymentMode == .freeTrial {
            let unitName: String
            switch offer.period.unit {
            case .day: unitName = "天"
            case .week: unitName = "周"
            case .month: unitName = "个月"
            case .year: unitName = "年"
            }
            return "\(offer.period.value) \(unitName)免费试用"
        }

        return "优惠价 \(offer.displayPrice)"
    }
}

@MainActor
final class AtEaseSubscriptionService: ObservableObject {
    @Published private(set) var state: AtEaseSubscriptionState
    @Published private(set) var expiresAt: Date?
    @Published private(set) var products: [SubscriptionProduct] = []
    @Published private(set) var isLoadingProducts = false
    @Published private(set) var isWorking = false
    @Published private(set) var errorMessage: String?

    private let provider: SubscriptionStoreProviding
    private let cache: SubscriptionStateStoring

    init(
        provider: SubscriptionStoreProviding = StoreKitSubscriptionProvider(),
        cache: SubscriptionStateStoring = UserDefaultsSubscriptionCache()
    ) {
        self.provider = provider
        self.cache = cache

        if let cached = cache.load() {
            state = cached.state
            expiresAt = cached.expiresAt
        } else {
            state = .notSubscribed
        }
    }

    var isSubscribed: Bool {
        state == .subscribed
    }

    func refresh() async {
        do {
            let refreshed = try await provider.refreshEntitlement()
            apply(refreshed, productID: nil)
            errorMessage = nil
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? SubscriptionError.storeUnavailable.errorDescription
        }
    }

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }

        do {
            products = try await provider.products()
            errorMessage = nil
        } catch {
            products = []
            errorMessage = (error as? LocalizedError)?.errorDescription ?? SubscriptionError.storeUnavailable.errorDescription
        }
    }

    func purchase(_ product: SubscriptionProduct) async {
        guard !isWorking else { return }

        isWorking = true
        defer { isWorking = false }

        do {
            let refreshed = try await provider.purchase(productID: product.id)
            apply(refreshed, productID: product.id)
            errorMessage = nil
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? SubscriptionError.storeUnavailable.errorDescription
        }
    }

    func restore() async {
        guard !isWorking else { return }

        isWorking = true
        defer { isWorking = false }

        do {
            let refreshed = try await provider.restore()
            apply(refreshed, productID: nil)
            errorMessage = restoredMessage(for: refreshed)
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? SubscriptionError.storeUnavailable.errorDescription
        }
    }

    private func apply(_ state: AtEaseSubscriptionState, productID: String?) {
        self.state = state
        if state == .notSubscribed {
            expiresAt = nil
        }

        let cached = CachedSubscriptionState(
            state: state,
            expiresAt: expiresAt,
            cachedAt: Date(),
            lastProductID: productID ?? cache.load()?.lastProductID
        )
        cache.save(cached)
    }

    private func restoredMessage(for state: AtEaseSubscriptionState) -> String {
        state == .subscribed ? "已恢复订阅。" : "没有找到可恢复的订阅。"
    }
}
