import Foundation

enum AmbientRecordingLibrary {
    static func filtered(_ recordings: [AmbientRecordingModel], query: String) -> [AmbientRecordingModel] {
        filtered(recordings, query: query, category: "全部")
    }

    static func filtered(
        _ recordings: [AmbientRecordingModel],
        query: String,
        category: String
    ) -> [AmbientRecordingModel] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return recordings.filter { recording in
            let matchesCategory = category == "全部" || recording.category == category
            let matchesQuery = trimmed.isEmpty || recording.title.localizedCaseInsensitiveContains(trimmed)
            return matchesCategory && matchesQuery
        }
    }
}

enum AmbientRecordingCategory: String, CaseIterable, Identifiable {
    case all = "全部"
    case nature = "自然"
    case city = "城市"
    case home = "居家"
    case night = "夜晚"

    var id: String {
        rawValue
    }
}
