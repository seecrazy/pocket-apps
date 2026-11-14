import Foundation
import SwiftData

@Model
final class GuidedContentStateModel {
    var id: UUID
    var contentID: String
    var isFavorite: Bool
    var lastPlayedAt: Date?
    var completedSeconds: Int
    var isCompleted: Bool
    var downloadState: String

    init(
        id: UUID = UUID(),
        contentID: String,
        isFavorite: Bool = false,
        lastPlayedAt: Date? = nil,
        completedSeconds: Int = 0,
        isCompleted: Bool = false,
        downloadState: String = ContentDownloadState.notApplicable.rawValue
    ) {
        self.id = id
        self.contentID = contentID
        self.isFavorite = isFavorite
        self.lastPlayedAt = lastPlayedAt
        self.completedSeconds = completedSeconds
        self.isCompleted = isCompleted
        self.downloadState = downloadState
    }
}
