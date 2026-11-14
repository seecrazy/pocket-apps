import Foundation
import SwiftData

@Model
final class AmbientRecordingModel {
    var id: UUID
    var title: String
    var category: String
    var startedAt: Date
    var duration: TimeInterval
    var fileURLString: String

    init(
        id: UUID = UUID(),
        title: String,
        category: String = "自然",
        startedAt: Date,
        duration: TimeInterval,
        fileURLString: String
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.startedAt = startedAt
        self.duration = duration
        self.fileURLString = fileURLString
    }

    var fileURL: URL {
        URL(filePath: fileURLString)
    }
}
