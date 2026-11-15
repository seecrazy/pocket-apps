import AVFAudio
import Foundation

@MainActor
final class AtEaseAudioGuide: NSObject, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private let session = AVAudioSession.sharedInstance()
    private var audioPlayer: AVAudioPlayer?

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String, assetName: String? = nil) {
        if let assetName, let url = AtEaseVoiceLocator.url(forAsset: assetName) {
            playTTS(url: url, fallbackText: text)
            return
        }
        synthesize(text)
    }

    func speak(
        contentID: String,
        stepID: String,
        fallbackText: String
    ) {
        if let url = AtEaseVoiceLocator.url(
            forContentID: contentID,
            stepID: stepID
        ) {
            playTTS(url: url, fallbackText: fallbackText)
            return
        }
        synthesize(fallbackText)
    }

    func phase(_ phase: BreathingPhase) {
        speak(phase.title, assetName: AtEaseVoiceLocator.assetName(for: phase))
    }

    func startTimer() {
        speak("开始", assetName: "voice-timer-start")
    }

    func finish() {
        speak("练习结束", assetName: "voice-timer-finish")
    }

    private func playTTS(url: URL, fallbackText: String) {
        configureAudioSession()

        stopSpeaking()
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.prepareToPlay()
            player.volume = 0.78
            guard player.play() else {
                synthesize(fallbackText)
                return
            }
            audioPlayer = player
        } catch {
            synthesize(fallbackText)
        }
    }

    private func synthesize(_ text: String) {
        configureAudioSession()
        stopSpeaking()

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = max(0.42, AVSpeechUtteranceDefaultSpeechRate - 0.05)
        utterance.pitchMultiplier = 0.95
        utterance.volume = 0.75
        utterance.postUtteranceDelay = 0.1
        synthesizer.speak(utterance)
    }

    private func stopSpeaking() {
        audioPlayer?.stop()
        audioPlayer = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func configureAudioSession() {
        do {
            try session.setCategory(
                .playback,
                mode: .spokenAudio,
                options: [.duckOthers, .mixWithOthers]
            )
            try session.setActive(true, options: [.notifyOthersOnDeactivation])
        } catch {
            // 语音引导失败不应阻断练习；视觉与触觉仍然可用。
        }
    }
}

extension AtEaseAudioGuide: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        // 保持会话活跃，避免后台音景被语音结束打断。
    }
}
