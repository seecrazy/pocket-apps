import AVFAudio
import Foundation

final class AudioRecorderService: ObservableObject {
    @Published private(set) var isRecording = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var currentFileURL: URL?
    private(set) var lastFileURL: URL?
    private var recorder: AVAudioRecorder?

    func startRecording() -> URL? {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
        } catch {
            errorMessage = "无法准备录音会话：\(error.localizedDescription)"
            return nil
        }

        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appending(path: "Ambient-\(Int(Date().timeIntervalSince1970)).m4a")

        do {
            recorder = try AVAudioRecorder(url: fileURL, settings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
            ])
            recorder?.record()
            isRecording = true
            currentFileURL = fileURL
            errorMessage = nil
            return fileURL
        } catch {
            errorMessage = "无法开始录音：\(error.localizedDescription)"
            return nil
        }
    }

    func stopRecording() -> TimeInterval {
        let duration = recorder?.currentTime ?? 0
        recorder?.stop()
        recorder = nil
        isRecording = false
        lastFileURL = currentFileURL
        currentFileURL = nil
        return duration
    }

    func clearLastFileURL() {
        lastFileURL = nil
    }
}
