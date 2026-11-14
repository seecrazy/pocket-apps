import Foundation
import SwiftData

@Model
final class FocusSessionModel {
    var id: UUID
    var startedAt: Date
    var plannedMinutes: Int
    var intention: String?
    var pausedAt: Date?
    var pausedSeconds: Int
    var completedAt: Date?
    var status: String

    init(
        id: UUID = UUID(),
        startedAt: Date,
        plannedMinutes: Int,
        intention: String? = nil,
        pausedAt: Date? = nil,
        pausedSeconds: Int = 0,
        completedAt: Date? = nil,
        status: String = FocusSessionStatus.running.rawValue
    ) {
        self.id = id
        self.startedAt = startedAt
        self.plannedMinutes = plannedMinutes
        self.intention = intention
        self.pausedAt = pausedAt
        self.pausedSeconds = pausedSeconds
        self.completedAt = completedAt
        self.status = status
    }
}

enum FocusSessionStatus: String {
    case running
    case paused
    case completed
    case abandoned
}
