import Foundation

enum AmbientRecordingLibrary {
    static func filtered(_ recordings: [AmbientRecordingModel], query: String) -> [AmbientRecordingModel] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return recordings }
        return recordings.filter { $0.title.localizedCaseInsensitiveContains(trimmed) }
    }
}
