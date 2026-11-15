import Foundation

enum MeditationLibraryFilter: String, CaseIterable, Identifiable {
    case all
    case favorites

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .all: return "全部"
        case .favorites: return "收藏"
        }
    }
}
