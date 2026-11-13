import Foundation
import SwiftData

@Model
final class StashCollectionModel {
    var id: UUID
    var name: String
    var lastModifiedAt: Date

    init(id: UUID = UUID(), name: String, lastModifiedAt: Date) {
        self.id = id
        self.name = name
        self.lastModifiedAt = lastModifiedAt
    }
}

@Model
final class StashedTabModel {
    var id: UUID
    var title: String
    var urlString: String
    var collectionID: UUID
    var lastModifiedAt: Date
    var isRead: Bool
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        title: String,
        urlString: String,
        collectionID: UUID,
        lastModifiedAt: Date,
        isRead: Bool = false,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.urlString = urlString
        self.collectionID = collectionID
        self.lastModifiedAt = lastModifiedAt
        self.isRead = isRead
        self.isFavorite = isFavorite
    }

    var url: URL? {
        URL(string: urlString)
    }
}
