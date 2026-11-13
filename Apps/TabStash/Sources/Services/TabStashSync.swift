import Foundation
import SwiftData

enum TabStashSyncError: Error, LocalizedError {
    case unsupportedSchema
    case malformedJSON

    var errorDescription: String? {
        switch self {
        case .unsupportedSchema:
            return "导入文件 schema 版本不受支持。"
        case .malformedJSON:
            return "导入文件不是有效的 PocketTabStash.v1 JSON。"
        }
    }
}

struct StashSyncDocument: Codable, Equatable {
    var schemaVersion: Int
    var generatedAt: Date
    var collections: [StashSyncCollectionDTO]
    var tabs: [StashSyncTabDTO]
}

struct StashSyncCollectionDTO: Codable, Equatable {
    var id: UUID
    var name: String
    var lastModifiedAt: Date
}

struct StashSyncTabDTO: Codable, Equatable {
    var id: UUID
    var title: String
    var url: String
    var collectionID: UUID
    var lastModifiedAt: Date
    var isRead: Bool
    var isFavorite: Bool
}

struct StashSyncImportResult: Equatable {
    var insertedCollections = 0
    var insertedTabs = 0
    var updatedTabs = 0
    var skippedInvalidURLs = 0
    var createdFallbackCollection = false
}

private struct TabStashMergeContext {
    var collectionLookup: [UUID: StashCollectionModel]
    var tabLookup: [UUID: StashedTabModel]
    var fallbackCollectionID: UUID
}

enum TabStashSyncService {
    static let schemaName = "PocketTabStash.v1"
    private static let formatter = ISO8601DateFormatter()

    static func decode(_ data: Data) throws -> StashSyncDocument {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            guard let date = formatter.date(from: string) else {
                throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date")
            }
            return date
        }

        let document = try decoder.decode(StashSyncDocument.self, from: data)
        guard document.schemaVersion == 1 else {
            throw TabStashSyncError.unsupportedSchema
        }
        return document
    }

    static func encode(_ document: StashSyncDocument) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(formatter.string(from: date))
        }
        return try encoder.encode(document)
    }

    static func makeDocument(
        collections: [StashCollectionModel],
        tabs: [StashedTabModel],
        generatedAt: Date = Date()
    ) -> StashSyncDocument {
        StashSyncDocument(
            schemaVersion: 1,
            generatedAt: generatedAt,
            collections: collections.map {
                StashSyncCollectionDTO(id: $0.id, name: $0.name, lastModifiedAt: $0.lastModifiedAt)
            },
            tabs: tabs.map {
                StashSyncTabDTO(
                    id: $0.id,
                    title: $0.title,
                    url: $0.urlString,
                    collectionID: $0.collectionID,
                    lastModifiedAt: $0.lastModifiedAt,
                    isRead: $0.isRead,
                    isFavorite: $0.isFavorite
                )
            }
        )
    }

    @discardableResult
    static func importDocument(_ document: StashSyncDocument, into context: ModelContext) throws -> StashSyncImportResult {
        var result = StashSyncImportResult()
        let existingCollections = try context.fetch(FetchDescriptor<StashCollectionModel>())
        let existingTabs = try context.fetch(FetchDescriptor<StashedTabModel>())

        var collectionLookup = Dictionary(uniqueKeysWithValues: existingCollections.map { ($0.id, $0) })
        var tabLookup = Dictionary(uniqueKeysWithValues: existingTabs.map { ($0.id, $0) })

        insertCollections(from: document, into: context, collectionLookup: &collectionLookup, result: &result)
        let fallbackCollectionID = prepareFallbackCollection(
            from: document,
            into: context,
            collectionLookup: &collectionLookup,
            result: &result
        )
        var mergeContext = TabStashMergeContext(
            collectionLookup: collectionLookup,
            tabLookup: tabLookup,
            fallbackCollectionID: fallbackCollectionID
        )
        mergeTabs(
            from: document,
            into: context,
            mergeContext: &mergeContext,
            result: &result
        )

        try context.save()
        return result
    }

    private static func insertCollections(
        from document: StashSyncDocument,
        into context: ModelContext,
        collectionLookup: inout [UUID: StashCollectionModel],
        result: inout StashSyncImportResult
    ) {
        for dto in document.collections where collectionLookup[dto.id] == nil {
            let model = StashCollectionModel(id: dto.id, name: dto.name, lastModifiedAt: dto.lastModifiedAt)
            context.insert(model)
            collectionLookup[dto.id] = model
            result.insertedCollections += 1
        }
    }

    private static func prepareFallbackCollection(
        from document: StashSyncDocument,
        into context: ModelContext,
        collectionLookup: inout [UUID: StashCollectionModel],
        result: inout StashSyncImportResult
    ) -> UUID {
        let needsFallback = document.tabs.contains { collectionLookup[$0.collectionID] == nil }
        let fallbackCollectionID = UUID()
        if needsFallback {
            let fallback = StashCollectionModel(
                id: fallbackCollectionID,
                name: "导入集合",
                lastModifiedAt: document.generatedAt
            )
            context.insert(fallback)
            collectionLookup[fallbackCollectionID] = fallback
            result.createdFallbackCollection = true
        }
        return fallbackCollectionID
    }

    private static func mergeTabs(
        from document: StashSyncDocument,
        into context: ModelContext,
        mergeContext: inout TabStashMergeContext,
        result: inout StashSyncImportResult
    ) {
        let collectionLookup = mergeContext.collectionLookup
        let fallbackCollectionID = mergeContext.fallbackCollectionID

        for dto in document.tabs {
            guard let url = URL(string: dto.url), url.host != nil else {
                result.skippedInvalidURLs += 1
                continue
            }

            let collectionID = collectionLookup[dto.collectionID] == nil ? fallbackCollectionID : dto.collectionID

            if let existing = mergeContext.tabLookup[dto.id] {
                guard dto.lastModifiedAt > existing.lastModifiedAt else { continue }
                existing.title = dto.title
                existing.urlString = dto.url
                existing.collectionID = collectionID
                existing.lastModifiedAt = dto.lastModifiedAt
                existing.isRead = dto.isRead
                existing.isFavorite = dto.isFavorite
                result.updatedTabs += 1
            } else {
                let model = StashedTabModel(
                    id: dto.id,
                    title: dto.title,
                    urlString: dto.url,
                    collectionID: collectionID,
                    lastModifiedAt: dto.lastModifiedAt,
                    isRead: dto.isRead,
                    isFavorite: dto.isFavorite
                )
                context.insert(model)
                mergeContext.tabLookup[dto.id] = model
                result.insertedTabs += 1
            }
        }
    }
}
