import AVFAudio
import Foundation
import UserNotifications

public enum PocketPermission {
    case notifications
    case microphone
}

public enum PermissionStatus {
    case notDetermined
    case granted
    case denied
}

public protocol PermissionController {
    func status(for permission: PocketPermission) async -> PermissionStatus
    func request(_ permission: PocketPermission) async -> PermissionStatus
}

public struct SystemPermissionController: PermissionController {
    public init() {}

    public func status(for permission: PocketPermission) async -> PermissionStatus {
        switch permission {
        case .notifications:
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            return Self.map(settings.authorizationStatus)
        case .microphone:
            return Self.map(AVAudioApplication.shared.recordPermission)
        }
    }

    public func request(_ permission: PocketPermission) async -> PermissionStatus {
        switch permission {
        case .notifications:
            let granted = await (try? UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])) ?? false
            return granted ? .granted : .denied
        case .microphone:
            let granted = await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
            return granted ? .granted : .denied
        }
    }

    private static func map(_ status: UNAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .notDetermined: return .notDetermined
        case .denied, .ephemeral: return .denied
        case .authorized, .provisional: return .granted
        @unknown default: return .notDetermined
        }
    }

    private static func map(_ state: AVAudioApplication.recordPermission) -> PermissionStatus {
        switch state {
        case .undetermined: return .notDetermined
        case .denied: return .denied
        case .granted: return .granted
        @unknown default: return .notDetermined
        }
    }
}
