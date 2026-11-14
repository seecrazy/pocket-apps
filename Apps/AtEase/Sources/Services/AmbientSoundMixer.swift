import AVFAudio
import Foundation

enum AmbientSound: String, CaseIterable, Identifiable {
    case rain
    case stream
    case insects

    var id: String {
        rawValue
    }

    var title: String {
        switch self {
        case .rain: return "雨声"
        case .stream: return "流水"
        case .insects: return "虫鸣"
        }
    }

    var subtitle: String {
        switch self {
        case .rain: return "安全感与休息提示"
        case .stream: return "稳定、低侵入"
        case .insects: return "夜间自然声"
        }
    }
}

struct AmbientSoundLevel: Codable, Equatable {
    var rain: Double = 0
    var stream: Double = 0
    var insects: Double = 0
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

    private func startIfNecessary() {
        let active = [levels.rain, levels.stream, levels.insects].contains { $0 > 0 }
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
        let active = [levels.rain, levels.stream, levels.insects].contains { $0 > 0 }
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
    static func buffer(for sound: AmbientSound, duration: TimeInterval = 4, sampleRate: Double = 44100) -> AVAudioPCMBuffer {
        let frameCount = AVAudioFrameCount(max(1, duration * sampleRate))
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!

        guard let channelData = buffer.floatChannelData else { return buffer }
        let samples = channelData[0]

        for index in 0 ..< Int(frameCount) {
            let time = Double(index) / sampleRate
            samples[index] = Float(sample(sound: sound, time: time))
        }

        buffer.frameLength = frameCount
        return buffer
    }

    static func sample(sound: AmbientSound, time: TimeInterval) -> Double {
        switch sound {
        case .rain:
            return rainSample(time: time)
        case .stream:
            return streamSample(time: time)
        case .insects:
            return insectSample(time: time)
        }
    }

    static func rainSample(time: TimeInterval) -> Double {
        let base = Double.random(in: -1 ... 1)
        let previous = sin(time * 9.0)
        return max(-1, min(1, (base * 0.35 + previous * 0.18) * 0.55))
    }

    static func streamSample(time: TimeInterval) -> Double {
        let low = sin(time * 3.1) * 0.10
        let ripple = sin(time * 47.0 + sin(time * 5.0)) * 0.18
        let noise = Double.random(in: -0.20 ... 0.20)
        return max(-1, min(1, low + ripple + noise))
    }

    static func insectSample(time: TimeInterval) -> Double {
        let pulseFrequency = 18.0
        let pulse = max(0, sin(time * pulseFrequency * .pi))
        let tone = sin(time * 620.0)
        let amplitude = 0.12 + 0.08 * sin(time * 1.4)
        return max(-1, min(1, pulse * tone * amplitude))
    }
}
