import Foundation

enum MeditationTheme: String, Codable, CaseIterable, Identifiable {
    case focus
    case reset
    case emotion
    case sleep

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .focus: return "专注"
        case .reset: return "重置"
        case .emotion: return "情绪"
        case .sleep: return "睡前"
        }
    }
}

enum MeditationAudioKind: String, Codable {
    case scripted
    case bundled
    case remote
}

struct MeditationContentStep: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var text: String
    var durationSeconds: Int
    var hapticEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case text
        case durationSeconds
        case hapticEnabled
    }

    init(
        id: String,
        title: String,
        text: String,
        durationSeconds: Int,
        hapticEnabled: Bool = false
    ) {
        self.id = id
        self.title = title
        self.text = text
        self.durationSeconds = durationSeconds
        self.hapticEnabled = hapticEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        text = try container.decode(String.self, forKey: .text)
        durationSeconds = try container.decode(Int.self, forKey: .durationSeconds)
        hapticEnabled = try container.decodeIfPresent(Bool.self, forKey: .hapticEnabled) ?? false
    }
}

struct MeditationContentItem: Codable, Equatable, Identifiable {
    var id: String
    var title: String
    var subtitle: String
    var teacher: String
    var theme: MeditationTheme
    var durationSeconds: Int
    var audioKind: MeditationAudioKind
    var isSubscriptionRequired: Bool
    var steps: [MeditationContentStep]
}

struct AtEaseContentManifest: Codable, Equatable {
    static let currentSchemaVersion = 1

    var schemaVersion: Int
    var items: [MeditationContentItem]
}

struct MeditationContentValidationError: Error, LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}

enum MeditationContentValidator {
    static func validate(_ manifest: AtEaseContentManifest) throws {
        guard manifest.schemaVersion == AtEaseContentManifest.currentSchemaVersion else {
            throw MeditationContentValidationError(message: "内容 schema 版本不受支持。")
        }
        guard !manifest.items.isEmpty else {
            throw MeditationContentValidationError(message: "内容清单不能为空。")
        }

        let ids = manifest.items.map(\.id)
        guard Set(ids).count == ids.count else {
            throw MeditationContentValidationError(message: "内容 ID 重复。")
        }

        for item in manifest.items {
            guard !item.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw MeditationContentValidationError(message: "内容标题不能为空。")
            }
            guard item.durationSeconds > 0 else {
                throw MeditationContentValidationError(message: "内容时长必须大于 0。")
            }
            guard !item.steps.isEmpty else {
                throw MeditationContentValidationError(message: "内容步骤不能为空。")
            }

            let stepDuration = item.steps.reduce(0) { $0 + $1.durationSeconds }
            guard stepDuration == item.durationSeconds else {
                throw MeditationContentValidationError(message: "内容步骤时长与总时长不一致。")
            }

            let stepIDs = item.steps.map(\.id)
            guard Set(stepIDs).count == stepIDs.count else {
                throw MeditationContentValidationError(message: "内容步骤 ID 重复。")
            }
        }
    }
}

struct MeditationContentCatalogLoader {
    func load(from data: Data) throws -> AtEaseContentManifest {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let manifest = try decoder.decode(AtEaseContentManifest.self, from: data)
        try MeditationContentValidator.validate(manifest)
        return manifest
    }

    func loadBundledCatalog(bundle: Bundle = .main) throws -> AtEaseContentManifest {
        guard let url = bundle.url(forResource: "ContentCatalog", withExtension: "json") else {
            throw MeditationContentValidationError(message: "找不到内置内容清单。")
        }
        return try load(from: Data(contentsOf: url))
    }
}
