import AVFAudio
import Foundation

enum AmbientSound: String, CaseIterable, Identifiable {
    case rain
    case stream
    case insects
    case ocean
    case forest
    case wind

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .rain: return "雨声"
        case .stream: return "流水"
        case .insects: return "虫鸣"
        case .ocean: return "海浪"
        case .forest: return "森林"
        case .wind: return "风声"
        }
    }

    var subtitle: String {
        switch self {
        case .rain: return "安全感与休息提示"
        case .stream: return "稳定、低侵入"
        case .insects: return "夜间自然声"
        case .ocean: return "缓慢的潮汐节奏"
        case .forest: return "鸟鸣与树冠风声"
        case .wind: return "低频穿过林间"
        }
    }
}

struct AmbientSoundLevel: Codable, Equatable {
    var rain: Double = 0
    var stream: Double = 0
    var insects: Double = 0
    var ocean: Double = 0
    var forest: Double = 0
    var wind: Double = 0

    var isActive: Bool {
        [rain, stream, insects, ocean, forest, wind].contains { $0 > 0 }
    }

    enum CodingKeys: String, CodingKey {
        case rain, stream, insects, ocean, forest, wind
    }

    init() {}

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        rain = try container.decodeIfPresent(Double.self, forKey: .rain) ?? 0
        stream = try container.decodeIfPresent(Double.self, forKey: .stream) ?? 0
        insects = try container.decodeIfPresent(Double.self, forKey: .insects) ?? 0
        ocean = try container.decodeIfPresent(Double.self, forKey: .ocean) ?? 0
        forest = try container.decodeIfPresent(Double.self, forKey: .forest) ?? 0
        wind = try container.decodeIfPresent(Double.self, forKey: .wind) ?? 0
    }
}

@MainActor
final class AmbientSoundMixer: ObservableObject {
    @Published private(set) var isPlaying = false
    @Published private(set) var levels = AmbientSoundLevel()

    private var players: [AmbientSound: AVAudioPlayer] = [:]

    nonisolated static func assetURL(for sound: AmbientSound, bundle: Bundle = .main) -> URL? {
        if let url = bundle.url(
            forResource: sound.rawValue,
            withExtension: "m4a",
            subdirectory: "Sounds"
        ) {
            return url
        }
        return bundle.url(forResource: sound.rawValue, withExtension: "m4a")
    }

    func setLevel(_ level: Double, for sound: AmbientSound) {
        let normalized = min(max(level, 0), 1)
        switch sound {
        case .rain: levels.rain = normalized
        case .stream: levels.stream = normalized
        case .insects: levels.insects = normalized
        case .ocean: levels.ocean = normalized
        case .forest: levels.forest = normalized
        case .wind: levels.wind = normalized
        }

        if normalized > 0 {
            startPlayer(for: sound)
        } else {
            stopPlayer(for: sound)
        }
        applyVolumes()
        savePreset()
        refreshIsPlaying()
    }

    func setLevels(_ newLevels: AmbientSoundLevel) {
        levels = newLevels
        for sound in AmbientSound.allCases {
            if level(for: sound) > 0 {
                startPlayer(for: sound)
            } else {
                stopPlayer(for: sound)
            }
        }
        applyVolumes()
        savePreset()
        refreshIsPlaying()
    }

    func stop() {
        players.values.forEach { $0.stop() }
        players.removeAll()
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(
            false,
            options: [.notifyOthersOnDeactivation]
        )
    }

    func loadPreset() {
        guard let data = UserDefaults.standard.data(forKey: "atease.ambientSoundLevels"),
              let saved = try? JSONDecoder().decode(AmbientSoundLevel.self, from: data)
        else { return }
        levels = saved
    }

    private func startPlayer(for sound: AmbientSound) {
        if players[sound] != nil {
            players[sound]?.play()
            return
        }

        guard let url = Self.assetURL(for: sound) else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [.mixWithOthers]
            )
            try AVAudioSession.sharedInstance().setActive(
                true,
                options: [.notifyOthersOnDeactivation]
            )
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = Float(level(for: sound))
            player.prepareToPlay()
            guard player.play() else { return }
            players[sound] = player
        } catch {
            players[sound] = nil
        }
    }

    private func stopPlayer(for sound: AmbientSound) {
        players[sound]?.stop()
        players[sound] = nil
    }

    private func applyVolumes() {
        for sound in AmbientSound.allCases {
            players[sound]?.volume = Float(level(for: sound))
        }
    }

    private func refreshIsPlaying() {
        isPlaying = players.values.contains { $0.isPlaying }
    }

    private func level(for sound: AmbientSound) -> Double {
        switch sound {
        case .rain: return levels.rain
        case .stream: return levels.stream
        case .insects: return levels.insects
        case .ocean: return levels.ocean
        case .forest: return levels.forest
        case .wind: return levels.wind
        }
    }

    private func savePreset() {
        if let data = try? JSONEncoder().encode(levels) {
            UserDefaults.standard.set(data, forKey: "atease.ambientSoundLevels")
        }
    }
}
