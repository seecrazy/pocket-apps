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

    private var engine: AVAudioEngine?
    private var players: [AmbientSound: AVAudioPlayerNode] = [:]
    private var buffers: [AmbientSound: AVAudioPCMBuffer] = [:]

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
        applyVolumes()
        savePreset()
        startIfNecessary()
        stopIfNecessary()
    }

    func setLevels(_ newLevels: AmbientSoundLevel) {
        levels = newLevels
        applyVolumes()
        savePreset()
        startIfNecessary()
        stopIfNecessary()
    }

    func stop() {
        guard let engine else { return }
        players.values.forEach { $0.stop() }
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        isPlaying = false
    }

    func startDefaultAmbience(for theme: MeditationTheme) {
        loadPreset()
        guard !levels.isActive else {
            startIfNecessary()
            return
        }
        setLevel(0.22, for: theme.defaultAmbientSound)
    }

    private func startIfNecessary() {
        let active = levels.isActive
        guard active, !isPlaying else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true, options: [.notifyOthersOnDeactivation])
            let audioEngine = AVAudioEngine()
            engine = audioEngine

            for sound in AmbientSound.allCases {
                let player = AVAudioPlayerNode()
                audioEngine.attach(player)
                let pcmBuffer = AmbientBufferFactory.buffer(for: sound)
                buffers[sound] = pcmBuffer
                audioEngine.connect(player, to: audioEngine.mainMixerNode, format: pcmBuffer.format)
                players[sound] = player
            }

            try audioEngine.start()
            isPlaying = true
            applyVolumes()

            for sound in AmbientSound.allCases where volume(for: sound) > 0 {
                guard let player = players[sound], let pcmBuffer = buffers[sound] else { continue }
                player.scheduleBuffer(pcmBuffer, at: nil, options: .loops)
                player.play()
            }
        } catch {
            stop()
        }
    }

    private func stopIfNecessary() {
        let active = levels.isActive
        if !active, isPlaying {
            stop()
        }
    }

    private func applyVolumes() {
        for sound in AmbientSound.allCases {
            players[sound]?.volume = Float(volume(for: sound))
        }
    }

    private func volume(for sound: AmbientSound) -> Double {
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

    func loadPreset() {
        guard let data = UserDefaults.standard.data(forKey: "atease.ambientSoundLevels"),
              let saved = try? JSONDecoder().decode(AmbientSoundLevel.self, from: data)
        else { return }
        levels = saved
    }
}

enum AmbientBufferFactory {
    struct NoiseState {
        private var state: UInt64
        private var brownValue: Double = 0
        private var pinkBands: [Double] = [0, 0, 0, 0, 0, 0, 0]

        init(seed: UInt64) {
            state = seed == 0 ? 0x9E37_79B9_7F4A_7C15 : seed
        }

        mutating func uniform() -> Double {
            state &+= 0x9E37_79B9_7F4A_7C15
            var mixed = state
            mixed ^= mixed >> 30
            mixed &*= 0xBF58_476D_1CE4_E5B9
            mixed ^= mixed >> 27
            mixed &*= 0x94D0_49BB_1331_11EB
            mixed ^= mixed >> 31
            return Double(mixed >> 11) / Double(1 << 53) * 2 - 1
        }

        mutating func pink() -> Double {
            let white = uniform()
            pinkBands[0] = 0.99886 * pinkBands[0] + white * 0.0555179
            pinkBands[1] = 0.99332 * pinkBands[1] + white * 0.0750759
            pinkBands[2] = 0.96900 * pinkBands[2] + white * 0.1538520
            pinkBands[3] = 0.86650 * pinkBands[3] + white * 0.3104856
            pinkBands[4] = 0.55000 * pinkBands[4] + white * 0.5329522
            pinkBands[5] = -0.7616 * pinkBands[5] - white * 0.0168980
            let value = pinkBands[0] + pinkBands[1] + pinkBands[2] + pinkBands[3] + pinkBands[4] + pinkBands[5] + pinkBands[6] + white *
                0.5362
            pinkBands[6] = white * 0.115926
            return value * 0.11
        }

        mutating func brown() -> Double {
            brownValue = max(-0.98, min(0.98, brownValue + uniform() * 0.028))
            return brownValue * 3.0
        }
    }

    static func buffer(for sound: AmbientSound, duration: TimeInterval = 4, sampleRate: Double = 44100) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(max(1, duration * sampleRate))
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!

        guard let channelData = buffer.floatChannelData else { return buffer }
        let samples = channelData[0]
        var noise = NoiseState(seed: UInt64(abs(sound.rawValue.hashValue)) | 1)

        for index in 0 ..< Int(frameCount) {
            let time = Double(index) / sampleRate
            samples[index] = Float(sample(sound: sound, time: time, noise: &noise))
        }

        buffer.frameLength = frameCount
        smoothLoop(samples: samples, frameCount: Int(frameCount), sampleRate: sampleRate)
        return buffer
    }

    static func sample(
        sound: AmbientSound,
        time: TimeInterval,
        noise: inout NoiseState
    ) -> Double {
        switch sound {
        case .rain:
            return rainSample(time: time, noise: &noise)
        case .stream:
            return streamSample(time: time, noise: &noise)
        case .insects:
            return insectSample(time: time)
        case .ocean:
            return oceanSample(time: time, noise: &noise)
        case .forest:
            return forestSample(time: time, noise: &noise)
        case .wind:
            return windSample(time: time, noise: &noise)
        }
    }

    static func rainSample(time: TimeInterval, noise: inout NoiseState) -> Double {
        let drops = max(0, noise.uniform()) * max(0, sin(time * 17.0)) * 0.18
        let shower = noise.pink() * 0.48
        return clamp(shower + drops)
    }

    static func streamSample(time: TimeInterval, noise: inout NoiseState) -> Double {
        let low = sin(time * 3.1) * 0.10
        let ripple = sin(time * 47.0 + sin(time * 5.0)) * 0.18
        let water = noise.pink() * 0.38
        return clamp(low + ripple + water)
    }

    static func insectSample(time: TimeInterval) -> Double {
        let chirpCycle = time.truncatingRemainder(dividingBy: 2.8)
        let chirpGate: Double = chirpCycle < 0.32 ? 1 : 0
        let chirp = max(0, sin(chirpCycle * 54 * .pi)) * chirpGate
        let body = sin(time * 624.0) * chirp * 0.12
        let nightAir = sin(time * 0.9) * 0.018
        return clamp(body + nightAir)
    }

    static func oceanSample(time: TimeInterval, noise: inout NoiseState) -> Double {
        let wave = 0.5 + 0.5 * sin((time * 2 * .pi / 11.0) - 1.4)
        let swell = noise.brown() * (0.22 + wave * 0.36)
        return clamp(swell)
    }

    static func forestSample(time: TimeInterval, noise: inout NoiseState) -> Double {
        let canopy = noise.pink() * 0.18
        let birdCycle = time.truncatingRemainder(dividingBy: 4.6)
        let birdGate: Double = birdCycle > 1.4 && birdCycle < 1.9 ? 1 : 0
        let bird = sin(birdCycle * 22 * .pi) * birdGate * 0.055
        return clamp(canopy + bird)
    }

    static func windSample(time: TimeInterval, noise: inout NoiseState) -> Double {
        let gust = 0.45 + 0.55 * max(0, sin(time * 2 * .pi / 14.0) + 0.28 * sin(time * 1.1))
        let movingAir = noise.brown() * 0.20 * gust
        let rustle = noise.pink() * 0.08 * gust
        return clamp(movingAir + rustle)
    }

    private static func clamp(_ value: Double) -> Double {
        max(-1, min(1, value))
    }

    private static func smoothLoop(samples: UnsafeMutablePointer<Float>, frameCount: Int, sampleRate: Double) {
        let fadeFrames = min(frameCount / 2, Int(sampleRate * 0.08))
        guard fadeFrames > 0 else { return }

        for index in 0 ..< fadeFrames {
            let tailIndex = frameCount - fadeFrames + index
            let weight = Double(index) / Double(fadeFrames)
            let tail = Double(samples[tailIndex])
            let head = Double(samples[index])
            samples[tailIndex] = Float(tail * (1 - weight) + head * weight)
        }
    }
}

extension MeditationTheme {
    var defaultAmbientSound: AmbientSound {
        switch self {
        case .focus: return .stream
        case .reset: return .stream
        case .emotion: return .rain
        case .sleep: return .ocean
        }
    }
}
