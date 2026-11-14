import Foundation

enum SlowCardNotifications {
    static func id(for cardID: UUID) -> String {
        "slowcard.card.\(cardID.uuidString)"
    }
}

enum SlowCardPrompts {
    static let titles = [
        "给三个月后的我",
        "今天我想记住的事",
        "最近让我开心的小事",
        "我想对未来的自己说的话",
    ]
}

enum SlowCardFilter: String, CaseIterable, Identifiable {
    case all
    case traveling
    case received
    case favorite
    case archive

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .all: return "全部"
        case .traveling: return "在路上"
        case .received: return "已收到"
        case .favorite: return "收藏"
        case .archive: return "归档"
        }
    }
}

enum SlowCardLibrary {
    static func filtered(
        _ cards: [SlowCardModel],
        by filter: SlowCardFilter,
        now: Date = Date()
    ) -> [SlowCardModel] {
        cards.filter { card in
            switch filter {
            case .all: return true
            case .traveling: return card.status(now: now) == .traveling
            case .received: return card.status(now: now) == .received
            case .favorite: return card.isFavorite
            case .archive: return card.status(now: now) == .received && !card.isFavorite
            }
        }
    }
}
