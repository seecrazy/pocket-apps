import Foundation
import UserNotifications

public protocol NotificationScheduling {
    func requestAuthorization() async -> Bool
    func scheduleDailyReminder(
        id: String,
        hour: Int,
        minute: Int,
        title: String,
        body: String
    ) async throws
    func scheduleAt(
        id: String,
        date: Date,
        title: String,
        body: String
    ) async throws
    func cancel(ids: [String]) async
}

public struct SystemNotificationScheduler: NotificationScheduling {
    private let center: UNUserNotificationCenter

    public init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    public func requestAuthorization() async -> Bool {
        await (try? center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
    }

    public func scheduleDailyReminder(
        id: String,
        hour: Int,
        minute: Int,
        title: String,
        body: String
    ) async throws {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        try await add(id: id, title: title, body: body, trigger: trigger)
    }

    public func scheduleAt(
        id: String,
        date: Date,
        title: String,
        body: String
    ) async throws {
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        try await add(id: id, title: title, body: body, trigger: trigger)
    }

    public func cancel(ids: [String]) async {
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    private func add(id: String, title: String, body: String, trigger: UNNotificationTrigger) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        try await center.add(request)
    }
}
