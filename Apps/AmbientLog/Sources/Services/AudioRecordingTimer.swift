import Foundation

enum AudioRecordingTimer {
    static func format(seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        let normalizedSeconds = seconds % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, normalizedSeconds)
        }
        return String(format: "%02d:%02d", minutes, normalizedSeconds)
    }
}
