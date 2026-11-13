import Foundation
import SwiftData

@Model
final class SlowCardModel {
    var id: UUID
    var title: String
    var body: String
    var createdAt: Date
    var unlockAt: Date
    var isFavorite: Bool

    init(
        id: UUID = UUID(),
        title: String,
        body: String,
        createdAt: Date,
        unlockAt: Date,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.unlockAt = unlockAt
        self.isFavorite = isFavorite
    }
}

extension SlowCardModel {
    func status(now: Date = Date()) -> SlowCardStatus {
        unlockAt <= now ? .received : .traveling
    }
}

enum SlowCardStatus {
    case traveling
    case received
}
