@testable import AtEase
import XCTest

final class ReleaseReadinessTests: XCTestCase {
    func testPrivacyManifestIsLocalOnlyAndDeclaresRequiredAPIs() throws {
        let url = try XCTUnwrap(
            Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy")
        )
        let data = try Data(contentsOf: url)
        let plist = try XCTUnwrap(
            try PropertyListSerialization.propertyList(
                from: data,
                options: [],
                format: nil
            ) as? [String: Any]
        )

        XCTAssertEqual(plist["NSPrivacyTracking"] as? Bool, false)
        XCTAssertEqual((plist["NSPrivacyTrackingDomains"] as? [String])?.count, 0)
        XCTAssertEqual((plist["NSPrivacyCollectedDataTypes"] as? [[String: Any]])?.count, 0)

        let accessedAPIs = try XCTUnwrap(
            plist["NSPrivacyAccessedAPITypes"] as? [[String: Any]]
        )
        let accessedTypes = accessedAPIs.compactMap {
            $0["NSPrivacyAccessedAPIType"] as? String
        }
        XCTAssertTrue(accessedTypes.contains("NSPrivacyAccessedAPICategoryUserDefaults"))
        XCTAssertTrue(accessedTypes.contains("NSPrivacyAccessedAPICategoryFileTimestamp"))

        let reasons = accessedAPIs.flatMap {
            ($0["NSPrivacyAccessedAPITypeReasons"] as? [String]) ?? []
        }
        XCTAssertTrue(reasons.contains("CA92.1"))
        XCTAssertTrue(reasons.contains("C617.1"))
    }

    func testBackgroundAudioModeIsDeclaredForRemoteMeditationAudio() throws {
        let infoDictionary = try XCTUnwrap(Bundle.main.infoDictionary)
        let backgroundModes = try XCTUnwrap(
            infoDictionary["UIBackgroundModes"] as? [String]
        )
        XCTAssertTrue(backgroundModes.contains("audio"))
    }

    func testBundledCatalogHasNoPlaceholderRemoteAudioURL() throws {
        let manifest = try MeditationContentCatalogLoader().loadBundledCatalog()
        let rawCatalog = try String(
            contentsOf: XCTUnwrap(
                Bundle.main.url(forResource: "ContentCatalog", withExtension: "json")
            ),
            encoding: .utf8
        )

        XCTAssertFalse(rawCatalog.contains("example.com"))
        XCTAssertEqual(manifest.items.filter { !$0.isSubscriptionRequired }.count, 5)
        XCTAssertEqual(manifest.items.filter(\.isSubscriptionRequired).count, 3)
    }

    func testSubscriptionProductIDsAreStable() {
        XCTAssertEqual(
            StoreKitSubscriptionProvider.monthlyID,
            "com.pocketapps.atease.subscription.monthly"
        )
        XCTAssertEqual(
            StoreKitSubscriptionProvider.annualID,
            "com.pocketapps.atease.subscription.annual"
        )
    }

    func testReleaseVersionIsOneOne() throws {
        let infoDictionary = try XCTUnwrap(Bundle.main.infoDictionary)
        XCTAssertEqual(
            infoDictionary["CFBundleShortVersionString"] as? String,
            "1.1.0"
        )
    }
}
