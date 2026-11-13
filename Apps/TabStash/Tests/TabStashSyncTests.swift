import SwiftData
@testable import TabStash
import XCTest

final class TabStashSyncTests: XCTestCase {
    func testDecodesSchemaV1AndRejectsOtherVersions() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let document = StashSyncDocument(
            schemaVersion: 1,
            generatedAt: now,
            collections: [collection(id: UUID(), name: "阅读", modifiedAt: now)],
            tabs: [tab(id: UUID(), title: "Swift", url: "https://swift.org", collectionID: UUID(), modifiedAt: now)]
        )

        let data = try TabStashSyncService.encode(document)
        let decoded = try TabStashSyncService.decode(data)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.tabs.first?.title, "Swift")

        var unsupported = document
        unsupported.schemaVersion = 2
        let unsupportedData = try TabStashSyncService.encode(unsupported)
        XCTAssertThrowsError(try TabStashSyncService.decode(unsupportedData))
    }

    func testURLValidation() {
        let url = URL(string: "https://swift.org")
        XCTAssertEqual(url?.host, "swift.org")
        XCTAssertNil(URL(string: "not-a-url")?.host)
    }

    @MainActor
    func testImportInsertsValidTabsAndSkipsInvalidURLs() throws {
        let context = try makeContext()
        let base = Date(timeIntervalSince1970: 100)
        let collectionID = UUID()
        let tabID = UUID()
        let document = StashSyncDocument(
            schemaVersion: 1,
            generatedAt: base,
            collections: [collection(id: collectionID, name: "阅读", modifiedAt: base)],
            tabs: [
                tab(id: tabID, title: "旧标题", url: "https://swift.org", collectionID: collectionID, modifiedAt: base),
                tab(id: UUID(), title: "无效 URL", url: "not-a-url", collectionID: UUID(), modifiedAt: base),
            ]
        )

        let result = try TabStashSyncService.importDocument(document, into: context)
        XCTAssertEqual(result.insertedCollections, 1)
        XCTAssertEqual(result.insertedTabs, 1)
        XCTAssertEqual(result.skippedInvalidURLs, 1)
        XCTAssertTrue(result.createdFallbackCollection)

        let tabs = try context.fetch(FetchDescriptor<StashedTabModel>())
        XCTAssertEqual(tabs.count, 1)
        let valid = try XCTUnwrap(tabs.first { $0.id == tabID })
        XCTAssertEqual(valid.title, "旧标题")
    }

    @MainActor
    func testImportUpdatesWhenIncomingRecordIsNewer() throws {
        let context = try makeContext()
        let base = Date(timeIntervalSince1970: 100)
        let collectionID = UUID()
        let tabID = UUID()
        let original = StashSyncDocument(
            schemaVersion: 1,
            generatedAt: base,
            collections: [collection(id: collectionID, name: "阅读", modifiedAt: base)],
            tabs: [tab(id: tabID, title: "旧标题", url: "https://swift.org", collectionID: collectionID, modifiedAt: base)]
        )
        _ = try TabStashSyncService.importDocument(original, into: context)

        let updated = StashSyncDocument(
            schemaVersion: 1,
            generatedAt: base.addingTimeInterval(100),
            collections: [collection(id: collectionID, name: "阅读", modifiedAt: base)],
            tabs: [
                tab(
                    id: tabID,
                    title: "新标题",
                    url: "https://swift.org/documentation/",
                    collectionID: collectionID,
                    modifiedAt: base.addingTimeInterval(100),
                    isRead: true,
                    isFavorite: true
                ),
            ]
        )

        let result = try TabStashSyncService.importDocument(updated, into: context)
        XCTAssertEqual(result.updatedTabs, 1)
        XCTAssertEqual(result.insertedTabs, 0)

        let tabs = try context.fetch(FetchDescriptor<StashedTabModel>())
        let merged = try XCTUnwrap(tabs.first { $0.id == tabID })
        XCTAssertEqual(merged.title, "新标题")
        XCTAssertTrue(merged.isRead)
        XCTAssertTrue(merged.isFavorite)
    }

    @MainActor
    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: StashCollectionModel.self,
            StashedTabModel.self,
            configurations: configuration
        )
        return ModelContext(container)
    }

    private func collection(id: UUID, name: String, modifiedAt: Date) -> StashSyncCollectionDTO {
        StashSyncCollectionDTO(id: id, name: name, lastModifiedAt: modifiedAt)
    }

    private func tab(
        id: UUID,
        title: String,
        url: String,
        collectionID: UUID,
        modifiedAt: Date,
        isRead: Bool = false,
        isFavorite: Bool = false
    ) -> StashSyncTabDTO {
        StashSyncTabDTO(
            id: id,
            title: title,
            url: url,
            collectionID: collectionID,
            lastModifiedAt: modifiedAt,
            isRead: isRead,
            isFavorite: isFavorite
        )
    }
}
