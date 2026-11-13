import Foundation
import SwiftData

@Model
final class CheckInPlanModel {
    var id: UUID
    var title: String
    var reminderHour: Int
    var reminderMinute: Int
    var isEnabled: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        reminderHour: Int,
        reminderMinute: Int,
        isEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.reminderHour = reminderHour
        self.reminderMinute = reminderMinute
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }
}

@Model
final class CheckInRecordModel {
    var id: UUID
    var planID: UUID
    var day: Date
    var completedAt: Date?
    var note: String?

    init(
        id: UUID = UUID(),
        planID: UUID,
        day: Date,
        completedAt: Date? = nil,
        note: String? = nil
    ) {
        self.id = id
        self.planID = planID
        self.day = day
        self.completedAt = completedAt
        self.note = note
    }
}
