import Foundation
import PocketCore

public final class InMemoryNotificationScheduler: NotificationScheduling, @unchecked Sendable {
    private let lock = NSLock()
    private var dailyRequests: [String: ScheduledNotification] = [:]
    private var datedRequests: [String: ScheduledNotification] = [:]

    public var authorizationResult = true
    public var shouldThrow = false

    public struct ScheduledNotification {
        public let title: String
        public let body: String
    }

    public init() {}

    public func requestAuthorization() async -> Bool {
        authorizationResult
    }

    public func scheduleDailyReminder(
        id: String,
        hour: Int,
        minute: Int,
        title: String,
        body: String
    ) async throws {
        try recordScheduledRequest()
        lock.lock()
        dailyRequests[id] = ScheduledNotification(title: title, body: body)
        lock.unlock()
    }

    public func scheduleAt(
        id: String,
        date: Date,
        title: String,
        body: String
    ) async throws {
        try recordScheduledRequest()
        lock.lock()
        datedRequests[id] = ScheduledNotification(title: title, body: body)
        lock.unlock()
    }

    public func cancel(ids: [String]) async {
        lock.lock()
        for id in ids {
            dailyRequests.removeValue(forKey: id)
            datedRequests.removeValue(forKey: id)
        }
        lock.unlock()
    }

    public func dailyNotificationIDs() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(dailyRequests.keys)
    }

    public func datedNotificationIDs() -> [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(datedRequests.keys)
    }

    private func recordScheduledRequest() throws {
        lock.lock()
        let shouldThrow = shouldThrow
        lock.unlock()
        if shouldThrow {
            throw NotificationSchedulerError.requestFailed
        }
    }
}

public enum NotificationSchedulerError: Error {
    case requestFailed
}
