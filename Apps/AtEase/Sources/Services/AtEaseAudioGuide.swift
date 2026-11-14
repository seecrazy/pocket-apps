import AVFAudio
import Foundation

@MainActor
final class AtEaseAudioGuide: NSObject, ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    private let session = AVAudioSession.sharedInstance()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        configureAudioSession()

        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "zh-CN")
        utterance.rate = max(0.42, AVSpeechUtteranceDefaultSpeechRate - 0.05)
        utterance.pitchMultiplier = 0.95
        utterance.volume = 0.75
        utterance.postUtteranceDelay = 0.1
        synthesizer.speak(utterance)
    }

    func phase(_ phase: BreathingPhase) {
        speak(phase.title)
    }

    func startTimer() {
        speak("开始")
    }

    func finish() {
        speak("练习结束")
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
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            try? session.setActive(false, options: [.notifyOthersOnDeactivation])
        }
    }
}
