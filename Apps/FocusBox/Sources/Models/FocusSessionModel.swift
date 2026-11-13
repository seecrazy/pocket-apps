import Foundation
import SwiftData

@Model
final class FocusSessionModel {
    var id: UUID
    var startedAt: Date
    var plannedMinutes: Int
    var completedAt: Date?
    var status: String

    init(
        id: UUID = UUID(),
        startedAt: Date,
        plannedMinutes: Int,
        completedAt: Date? = nil,
        status: String = FocusSessionStatus.running.rawValue
    ) {
        self.id = id
        self.startedAt = startedAt
        self.plannedMinutes = plannedMinutes
        self.completedAt = completedAt
        self.status = status
    }
}

enum FocusSessionStatus: String {
    case running
    case completed
    case abandoned
}
