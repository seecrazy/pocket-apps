import Foundation
import SwiftData

@Model
final class AmbientRecordingModel {
    var id: UUID
    var title: String
    var startedAt: Date
    var duration: TimeInterval
    var fileURLString: String

    init(
        id: UUID = UUID(),
        title: String,
        startedAt: Date,
        duration: TimeInterval,
        fileURLString: String
    ) {
        self.id = id
        self.title = title
        self.startedAt = startedAt
        self.duration = duration
        self.fileURLString = fileURLString
    }

    var fileURL: URL {
        URL(filePath: fileURLString)
    }
}
