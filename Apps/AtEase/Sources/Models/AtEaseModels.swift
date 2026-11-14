import Foundation
import SwiftData

@Model
final class MoodCheckInModel {
    var id: UUID
    var moodLevel: Int
    var createdAt: Date

    init(id: UUID = UUID(), moodLevel: Int, createdAt: Date = Date()) {
        self.id = id
        self.moodLevel = moodLevel
        self.createdAt = createdAt
    }
}

@Model
final class PracticeSessionModel {
    var id: UUID
    var kind: String
    var startedAt: Date
    var endedAt: Date?
    var mindfulSeconds: Int
    var moodLevel: Int?

    init(
        id: UUID = UUID(),
        kind: AtEasePracticeKind,
        startedAt: Date = Date(),
        endedAt: Date? = nil,
        mindfulSeconds: Int,
        moodLevel: Int? = nil
    ) {
        self.id = id
        self.kind = kind.rawValue
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.mindfulSeconds = mindfulSeconds
        self.moodLevel = moodLevel
    }
}

enum AtEasePracticeKind: String, CaseIterable, Identifiable {
    case breath
    case timer
    case sos
    case guided
    case thoughtDistancing
    case bodyScan

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .breath: return "引导呼吸"
        case .timer: return "自由计时"
        case .sos: return "1 分钟 SOS"
        case .guided: return "引导冥想"
        case .thoughtDistancing: return "念头放下"
        case .bodyScan: return "触摸身体扫描"
        }
    }
}
